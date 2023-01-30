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