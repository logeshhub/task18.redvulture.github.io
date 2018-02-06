Clear-Host
Import-Module ActiveDirectory

#variable declaration to hold the group members


# get AD groups available in domain

$groupArray = get-adgroup -filter *  | sort name | select Name

#region retrieve Members of the Access Level Group
foreach ($grp in $groupArray)
   {

       if($grp.Name -eq "US-ETFS-AccessLevel-Advanced")
       {
       
         $etfsAdvanced = Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName

       }

       if($grp.Name -eq "US-ETFS-AccessLevel-Basic")
       {
        
         $etfsBasic= Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName
       
       }

       if($grp.Name -eq "US-ETFS-AccessLevel-Stakeholder")
       {

            $etfsStakeholder=Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName
       }


       if($grp.Name -eq "US-ETFS-EC-AccessLevel-Advanced")
       {

         $ecAdvanced = Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName

       }

       if($grp.Name -eq "US-ETFS-EC-AccessLevel-Basic")
       {
          $ecBasic = Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName

       }

       if($grp.Name -eq "US-ETFS-EC-AccessLevel-Stakeholder")
       {
         
         $ecStakeholder = Get-ADGroupMember -identity $grp.Name -Recursive | foreach{ get-aduser $_} | Get-ADUser -Property DisplayName | select SamAccountName,name,DisplayName


       }

   }
#endregion

#region Display Group Member
 # Display each access level group memeber
 
Write-Host "US-ETFS-AccessLevel-Advanced Members"
$etfsAdvanced

Write-Host "US-ETFS-AccessLevel-Basic Members"
$etfsBasic

Write-Host "US-ETFS-AccessLevel-Stakeholder Members"
$etfsStakeholder

Write-Host "US-ETFS-EC-AccessLevel-Advanced Members"
$ecAdvanced

Write-Host "US-ETFS-EC-AccessLevel-Basic Members"
$ecBasic
Write-Host "US-ETFS-EC-AccessLevel-Stakeholder Members"
$ecStakeholder
#endregion

#region ETFS Team Project
 # Iterate each Access Level Group related to ETFS team project and see if the member is present in another access level group

  foreach ($EtfsAdvmemberName in $etfsAdvanced)
    {
        
        if($etfsBasic.length -gt 0)
        {

                  foreach($EtfsBasciMemberName in $etfsBasic)
                  {
          
                        if($EtfsAdvmemberName.Name -eq $EtfsBasciMemberName.Name)
                        {
                          write-host   $EtfsAdvmemberName.Name + "is also a member of ETFS Basic Group, Need to remove it from the ETFS Basic Group"              
                        
                        }
          
                  }
          }


          if($etfsStakeholder.length -gt 0)
            {

                  foreach($EtfsStakeHolderMemberName in $etfsStakeholder)
                  {
          
                        if($EtfsAdvmemberName.Name -eq $EtfsStakeHolderMemberName.Name )
                        {
                          write-host   $EtfsAdvmemberName.Name + "is also a member of ETFS StackHolder Group, Need to remove it from the ETFS StackHolder Group"              
                        
                        }
          
                  }
          }
    }
#endregion

#region EC Team Project


# Iterate each Access Level Group related to ETFS team project and see if the member is present in another access level group

  foreach ($ECAdvmemberName in $ecAdvanced)
    {
        
        if($ecBasic.length -gt 0)
        {

                  foreach($ECBasciMemberName in $ecBasic)
                  {
          
                        if($ECAdvmemberName.Name -eq $ECBasciMemberName.Name)
                        {
                          write-host   $ECAdvmemberName.Name + "is also a member of EC Basic Group, Need to remove it from the EC Basic Group"              
                        
                        }
          
                  }
          }


          if($ecStakeholder.length -gt 0)
            {

                  foreach($EcStakeHolderMemberName in $ecStakeholder)
                  {
          
                        if($ECAdvmemberName.Name -eq $EcStakeHolderMemberName.Name )
                        {
                          write-host   $ECAdvmemberName.Name + "is also a member of EC StackHolder Group, Need to remove it from the EC StackHolder Group"              
                        
                        }
          
                  }
          }
    }

 #endregion
