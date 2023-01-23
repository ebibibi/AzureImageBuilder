####################
# Change To Japanese
####################
Install-Language ja-JP -CopyToSettings
Set-SystemPreferredUILanguage ja-JP
Set-WinHomeLocation -GeoId 0x7a
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
Set-TimeZone -Id "Tokyo Standard Time"

#########################
# Install PowerBI Desktop
#########################
winget install --id=Microsoft.PowerBI --silent
