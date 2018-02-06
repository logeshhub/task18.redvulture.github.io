#
# Service Account Password Notifier
#
# Query for the "US-ETFS-Service-Accounts" active directory group, and analyize the password age for each account.  Send an 
# email to Operation staff if the notification is less than the threshold set (currently 20 days).
#
# mob - 11/4/2014
#
$ExpireDays = 10
$SendingEmail = "semsops@mmm.com"
$ReceivingEmail = "meobrien@mmm.com","dkcarlson@mmm.com", "engregerson@mmm.com", "etaylor@mmm.com","cbenton@mmm.com", "krgarver@mmm.com", "sjaiswal@mmm.com", "vkumar7@mmm.com"
$SMTPHost="mail.mmm.com"
$ADServiceAccountGroupName = "US-ETFS-Service-Accounts"
Import-Module ActiveDirectory
$EmailMessage = ""
$Today = (get-date)
$AllUsers = Get-ADGroupMember -Identity $ADServiceAccountGroupName
$nl = [Environment]::NewLine

foreach ($User in $AllUsers)
{
    $ExpireDate = $null

	$Name = (Get-ADUser $User -properties PasswordExpired, PasswordNeverExpires, PasswordLastSet | foreach { $_.Name})
	$accountObj = Get-ADUser $Name -properties PasswordExpired, PasswordNeverExpires, PasswordLastSet

    if ($accountObj.PasswordExpired)
	{
		$EmailMessage += "Password of account: " + $accountObj.Name + " already expired!" + $nl
    }
	else
	{ 
        if ($accountObj.PasswordNeverExpires)
		{
            #$EmailMessage += "Password of account: " + $accountObj.Name + " is set to never expires!" + $nl
			echo "Password of account: " + $accountObj.Name + " is set to never expires!" + $nl
        }
		else
		{
            $passwordSetDate = $accountObj.PasswordLastSet

            if ($passwordSetDate -eq $null)
			{
                #$EmailMessage += "Password of account: " + $accountObj.Name + " has never been set!" + $nl
				echo "Password of account: " + $accountObj.Name + " has never been set!" + $nl
            }
			else
			{
                $maxPasswordAgeTimeSpan = $null

                $dfl = (get-addomain).DomainMode

                if ($dfl -ge 3)
				{ 
                    ## Greater than Windows2008 domain functional level
                    $accountFGPP = Get-ADUserResultantPasswordPolicy $accountObj

                    if ($accountFGPP -ne $null)
					{
                        $maxPasswordAgeTimeSpan = $accountFGPP.MaxPasswordAge
                    }
					else
					{
                        $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
                    }
                }
				else
				{
                    $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
                }

                if ($maxPasswordAgeTimeSpan -eq $null -or $maxPasswordAgeTimeSpan.TotalMilliseconds -eq 0)
				{
                    $EmailMessage += "MaxPasswordAge is not set for the domain or is set to zero!" + $nl
                }
				else
				{
                    
                    $ExpireDate = $passwordSetDate + $maxPasswordAgeTimeSpan
					$DaysToExpire = (New-TimeSpan -Start $Today -End $ExpireDate).Days
  
					if ($DaysToExpire -lt $ExpireDays)
					{
						$EmailMessage += "Password of account: " + $accountObj.Name + " expires on: " + ($passwordSetDate + $maxPasswordAgeTimeSpan) + $nl
					}
					else
					{
						echo "Password of account: " + $accountObj.Name + " expires on: " + ($passwordSetDate + $maxPasswordAgeTimeSpan) + $nl
					}
                }
            }
        }
    }
}

if ($EmailMessage.Length -gt 0)
{
	$EmailSubject="Password Expiry Notice"
	$EmailMessage += "

Sincerely, 

SEMS DevOps
"

	echo "$Name password expires in $DaysToExpire days - EMAIL SENT"
	Send-Mailmessage -smtpServer $SMTPHost -from $SendingEmail -to $ReceivingEmail -subject $EmailSubject -body $EmailMessage -priority High
}
