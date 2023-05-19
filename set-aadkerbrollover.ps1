### automate monthly kerberos key rollover
### run as scheduled task

function set-aadkerbrollover{

$adate = Get-Date -format "MMddyy-HHmm"

$logpath = "C:\AAD-kerberos-rollover\log\$adate.txt"

New-Item -Path $logpath

try {$CloudCred = Import-Clixml "[aad_serviceCloud.xml]"}
catch {write-output $_ | out-file -FilePath $logpath -Append}

try {$OnPremCred = Import-Clixml "[aad_service.xml]" }
catch {write-output $_ | out-file -FilePath $logpath -Append}

try {Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1"}
catch {write-output $_ | out-file -FilePath $logpath -Append}

try {New-AzureADSSOAuthenticationContext -CloudCredentials $CloudCred}
catch {write-output $_ | out-file -FilePath $logpath -Append}

 Update-AzureADSSOForest -OnPremCredentials $OnPremCred | out-file -filepath $logpath -append

 $emailgoods = Get-Content -Path $logpath | out-string

Send-MailMessage -To "[to email]" -From "[from email]" -SmtpServer "[your smtp]" -Body "REPORT: $emailgoods" -Subject "AAD Kerberos Key Rollover Alert"

}

set-aadkerbrollover
