### centralize reminders for expiring configurations. if a variety of email addresses are used when configuring SSO, this reduces surprises


function ExpiringSamlCerts {
    
    ### Connect to Azure
    $cloudcred = $null
    $cloudcred = import-CliXml -path "[cred.xml]"
    
    Connect-AzureAD -Credential $cloudcred
    
    # get the enterprise apps
    $madapps = Get-AzureADServicePrincipal -All $true | Where-Object {($_.Tags -contains "WindowsAzureActiveDirectoryGalleryApplicationNonPrimaryV1") -or ($_.Tags -contains "WindowsAzureActiveDirectoryCustomSingleSignOnApplication")} | Select DisplayName,ObjectID
    
    # clear and create hashtable
    $hash = $null
    $hash = @{}
    
    # for each app get KeyCredentials.enddate
    foreach ($app in $madapps){
        $theapp = Get-AzureADServicePrincipal -ObjectId $app.objectid
        $expiry = $theapp.KeyCredentials.enddate | Get-Unique
        $dangerzone = get-date
    
    # if enddate is not null and within 60 days of script running: get app name, enddate pack into hash table
        if ($expiry -ne $null){
                if (($expiry -lt $dangerzone.AddDays(60)) -and ($expiry -gt $dangerzone.AddDays(-2))){
                        $hash.add($theapp.displayname,$expiry)   
                }
            }
    }
    
    #sort the hash table
    $dataz = $hash.GetEnumerator() | sort Value 
    
    #make a 90s html email body
    $EmailBody += "<table width='100%' border='1'><tr><td><b>App Name</b></td><td><b>Cert Expiry</b></td></tr>"    
    foreach ($entry in $dataz){$EmailBody += "<tr><td>$($entry.Key)</td><td>$($entry.Value)</td></tr>"}
    $EmailBody += "</table><br />"
    
    #sail away sail away
    Send-MailMessage -From '[]' -To '[]' -Subject "Azure Enterprise Apps - Expiring SAML Signing Certs (next 60 days)" -BodyAsHtml -body $emailbody -smtp '[]'
    
    }
    
       
    ExpiringSamlCerts
    
    
