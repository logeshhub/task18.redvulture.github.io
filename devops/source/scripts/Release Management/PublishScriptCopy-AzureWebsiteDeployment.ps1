<#
You might have to run this first on your machine to make this work: 
  Set-ExecutionPolicy AllSigned -Scope CurrentUser
  Set-ExecutionPolicy Unrestricted -Scope CurrentUser

Download your publishsettings file from here
https://windows.azure.com/download/publishprofile.aspx

#>

# Fix Path
if (Test-Path .\Source) { CD .\Source\Dev\WebSite\PublishScripts\ }

# Remove the Publish script files in the builddrop location to copy latest files
Remove-Item \\semsnas2.mmm.com\builddrop\JarvisWeb_Azure\Deploy\PublishScript\*.* -Recurse -Force

# Copy a publish script files to builddrop location for azure deployment
COPY-ITEM -Path .\PublishScripts\* -Destination \\semsnas2.mmm.com\builddrop\JarvisWeb_Azure\Deploy\PublishScripts -Recurse -Force

