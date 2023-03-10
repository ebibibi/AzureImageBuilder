####################
# Change To Japanese
####################
Install-Language ja-JP -CopyToSettings
Set-SystemPreferredUILanguage ja-JP
Set-WinHomeLocation -GeoId 0x7a
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
Set-TimeZone -Id "Tokyo Standard Time"

####################
# Install chocolatey
####################
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#########################
# Install PowerBI Desktop
#########################
choco install powerbi -y

######################
# Download Sample Data
######################
if (!(Test-Path("C:\SampleData")))
{
    New-Item -ItemType Directory -Path "C:\SampleData"
}

$sampleExcelUrl = "https://go.microsoft.com/fwlink/?LinkID=521962"
$sampleExcelFilePath = "C:\SampleData\Financial Sample.xlsx"
Invoke-WebRequest -Uri $sampleExcelUrl -OutFile $sampleExcelFilePath

$sampleExcelUrl = "https://artifactsforproducts.blob.core.windows.net/7988762673375/%E3%83%87%E3%83%A2%E3%83%87%E3%83%BC%E3%82%BF.xlsx?sp=r&st=2023-02-01T08:00:48Z&se=2099-02-01T16:00:48Z&spr=https&sv=2021-06-08&sr=b&sig=fzLvhD%2BHimMJUW7yHudf7X7z3GfbMw2lmSPniHO%2BMLY%3D"
$sampleExcelFilePath = "C:\SampleData\Relation Sample.xlsx"
Invoke-WebRequest -Uri $sampleExcelUrl -OutFile $sampleExcelFilePath
