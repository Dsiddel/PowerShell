# ===============================================
#   Import Environment Specific Parameters
# ===============================================
param(
    [string]$ParamCloudUsername = "X",
    [string]$ParamCloudPassword = 'X',
    [string]$ParamCSVLocation = "X",
    [string]$ParamCommandsLocation = "X",
    [string]$ParamLogDir = "X"

)
# ===============================================
#   Set Variables
# ===============================================
$CloudUserName = $ParamCloudUsername
$CloudPassword = ConvertTo-SecureString -String $ParamCloudPassword -AsPlainText -Force
$Cloudcreds = New-Object System.Management.Automation.PSCredential -ArgumentList $ParamCloudUsername, $CloudPassword
$CSVLocation = $ParamCSVLocation                                                                   
$LogDir = $ParamLogDir																			                                                                                  
$Date = Get-Date -Format yyyy-MM-dd																			                                                                             
$Now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"																                                                                              
$Log = "$LogDir\$Date.txt"	



# ===============================================
#   Functions
# ===============================================

Get-PSSession | % {Remove-PSSession $_}
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cloudcreds -Authentication  Basic -AllowRedirection
Import-PSSession $Session        

function Export ($csvloc) {
    try {
    
        $types = @(
        "DiscoveryMailbox"
        ,"EquipmentMailbox"
        ,"GroupMailbox"
        ,"LegacyMailbox"
        ,"LinkedMailbox"
        ,"LinkedRoomMailbox"
        ,"RoomMailbox"
        ,"SchedulingMailbox"
        ,"SharedMailbox"
        ,"TeamMailbox"
        ,"UserMailbox"
        );

        $first = $true;

        $lines = @();

        foreach ($type in $types){

            echo "Getting mailboxes of $type"

            $permissions = Get-Mailbox -RecipientTypeDetails $type -ResultSize Unlimited | Get-MailboxPermission | Where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false};
            
        
            if ($first){


                $permissions `
                | Select Identity,User,@{Name='Access Rights';Expression={$_.AccessRights}},@{Name='MailboxType';Expression={$type}},InheritanceType,Deny,IsValid `
                | Export-Csv $csvloc �NoTypeInformation 

                $first = $false

            } else {


                $permissions `
                | Select Identity,User,@{Name='Access Rights';Expression={$_.AccessRights}},@{Name='MailboxType';Expression={$type}},InheritanceType,Deny,IsValid `
                | Export-Csv $csvloc �NoTypeInformation -Append
            }

            foreach ($p in $permissions)
            {
                $lines += "Add-MailboxPermission -Identity '$($p.Identity)' -User '$($p.User)' -AccessRights $($p.AccessRights) -InheritanceType $($p.InheritanceType)"
                
            }

            

        }

        $lines | Set-Content -Path $ParamCommandsLocation
                

                        
    } Catch {
        Write-Output "Could not get list of users" + ($_.Exception.Message) | Out-File "$Log" -Append
    }
}






# ===============================================
#   Core Script
# ===============================================

try{

    Export -csvloc $CSVLocation
} 
finally
{
    #Get-PSSession | % {Remove-PSSession $_}
    
}