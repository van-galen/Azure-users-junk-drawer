### this script is several years old and was something used in conjunction with the old adobe user sync tool
### posted it because it uses LDAP filters for SPEED vs get-aduser, get-adgroupmember type stuff for filtering


function Sync-AdobeUserMembership {
    [CmdletBinding()]
	
    #exists to search everything
	$LDAProot = 'LDAP://DC=your,DC=domain,DC=here'
	
    #sets paged query default - groups of 1000
    $pg = '1000'
    
    $GroupMappings = @(
	 	
        @{
            # employee-related variable values - active users vs membership of AD user sync adobe group
            LDAPTarget = 'LDAP://OU=Employees,OU=Accounts,DC=your,DC=domain,DC=here'
			UserFilter = '(&(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'				
			AdobeUserFilter = '(&(objectCategory=person)(memberOf=CN=AdobeUserSync-Employee,OU=Resources,OU=Groups,DC=your,DC=domain,DC=here))'
			ADGroupName = 'AdobeUserSync-Employee'          
        }
        ,
        @{
            # student-related variable values - active users vs membership of AD user sync adobe group
		    LDAPTarget = 'LDAP://OU=Students,OU=Accounts,DC=your,DC=domain,DC=here'
			UserFilter = '(&(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'				
			AdobeUserFilter = '(&(objectCategory=person)(memberOf=CN=AdobeUserSync-Student,OU=Resources,OU=Groups,DC=your,DC=domain,DC=here))'
			ADGroupName = 'AdobeUserSync-Student' 
        }
        ,
        @{
            # get group membership and compare to just active members of the group
            LDAPTarget = 'LDAP://DC=your,DC=domain,DC=here'
            UserFilter = '(&(objectCategory=person)(memberOf=CN=AdobeUserSync-LicensedUser,OU=Resources,OU=Groups,DC=your,DC=domain,DC=here)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'				
            AdobeUserFilter = '(&(objectCategory=person)(memberOf=CN=AdobeUserSync-LicensedUser,OU=Resources,OU=Groups,DC=your,DC=domain,DC=here))'
            ADGroupName = 'AdobeUserSync-LicensedUser' 
        }
    )

    ForEach ($group in $GroupMappings) {
		

		$Searcher = New-Object DirectoryServices.DirectorySearcher
		$Searcher.SearchRoot = $LDAProot
		$Searcher.Filter = $group['AdobeUserFilter']
		$Searcher.PageSize = $pg
		$CurrentMembersList = $Searcher.FindAll() | Sort-Object path

        $CurrentMembers = $CurrentMembersList.properties.samaccountname 


		$Searcher2 = New-Object DirectoryServices.DirectorySearcher
		$Searcher2.SearchRoot = $group['LDAPTarget']
		$Searcher2.Filter = $group['UserFilter']
		$Searcher2.PageSize = $pg
		$CorrectMembersList = $Searcher2.FindAll() | Sort-Object path

		$CorrectMembers = $CorrectMembersList.properties.samaccountname 

        $comparisons = Compare-Object $CurrentMembers $CorrectMembers

        $AddMembers = $comparisons | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object InputObject

        $RemoveMembers = $comparisons | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object InputObject


        ForEach ($Removal in $RemoveMembers.InputObject) {

           Remove-ADPrincipalGroupMembership $Removal $group['ADGroupName'] -confirm:$false #-WhatIf

        }
        
		
        ForEach ($Addition in $AddMembers.InputObject) {

            Add-ADPrincipalGroupMembership $Addition $group['ADGroupName'] #-WhatIf
            
        }
        
    }
}

# run the actual thing
# Sync-AdobeUserMembership
