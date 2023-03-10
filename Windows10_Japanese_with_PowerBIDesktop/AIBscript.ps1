Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault
Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity


# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup = "CustomImages-Rg"

# location (see possible locations in main docs)
$location1 = "japaneast"
$location2 = "japanwest"

# your subscription, this will get your current subscription
$subscriptionID = $currentAzContext.Subscription.Id

# image template name
$imageTemplateName = "windows10_japanese"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName = "sigOutput"

# create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location1

# setup role def names, these need to be unique
$timeInt = $(get-date -UFormat "%s")
$imageRoleDefName = "Azure Image Builder Image Def" + $timeInt
$identityName = "aibIdentity" + $timeInt

## Add AZ PS modules to support AzUserAssignedIdentity and Az AIB
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object { Install-Module -Name $_ -AllowPrerelease }

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location1

$identityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

$aibRoleImageCreationUrl = "https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# wait for creation
$def = $null
do {
    Start-Sleep -s 10
    Write-Host "Check if role definition exists..."
    $def = Get-AzRoleDefinition -Name $imageRoleDefName
    $def
} while (($def.Name -eq $imageRoleDefName) -eq $false)

# grant role definition to image builder service principal
$success = $false
do {
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
    if($? -eq $true) {
        $success = $true
    }
    else {
        Write-Host "Failed to grant role definition to image builder service principal, retrying..."
        Start-Sleep -s 10
    }
} while ($success -eq $false)

# define azure compute gallery (shared image gallery)
$sigGalleryName = "mycomputegallery"
$imageDefName = "windows10_japanese"

# create gallery
New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup  -Location $location1

# create gallery definition
$ConfidentialVMSupported = @{Name = 'SecurityType'; Value = 'TrustedLaunch' }
$features = @($ConfidentialVMSupported)
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location1 -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'myCo' -Offer 'Windows' -Sku 'win10' -HyperVGeneration V2 -Feature $features

$templateUrl = "https://raw.githubusercontent.com/ebibibi/AzureImageBuilder/main/Windows10_Japanese_with_PowerBIDesktop/localize.json"
$templateFilePath = "localize.json"

Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>', $location1) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>', $runOutputName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>', $imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>', $sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>', $identityNameResourceId) | Set-Content -Path $templateFilePath


New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -TemplateParameterObject @{"api-Version" = "2020-02-14" } -imageTemplateName $imageTemplateName -svclocation $location1

Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName -NoWait

$versionName = "1.0.0"
$region1 = @{Name=$location1;ReplicaCount=1}
$region2 = @{Name=$location2;ReplicaCount=1}
$targetRegions = @($region1,$region2)

do {
    $version = Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup -GalleryName $sigGalleryName -GalleryImageDefinitionName $imageDefName
} while ($null -eq $version.Name)
Update-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup -GalleryName $sigGalleryName -GalleryImageDefinitionName $imageDefName -Name $version.Name -ReplicaCount 1 -TargetRegion $targetRegions
