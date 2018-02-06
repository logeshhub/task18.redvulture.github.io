# In oder to run this script we need to install first of all "Git for windows" and then set the environment variable path for 'git'
# Reference link "http://learnaholic.me/2012/10/12/make-powershell-and-git-suck-less-on-windows/"
# first make sure that 'git' command is recongnized by windows by running 'git' command in PowerShell or cmd
# gi clone <git_teamProject_url>
# clone the git repository to local folder and then iterate recursively to find all the files in the git repository

# change to the directory in which we want to clone the repository.

cd D:\_tfs_data\git

git clone https://tfsqa.mmm.com/tfs/DefaultCollection/_git/CRS

get-childitem  -rec | where {!$_.PSIsContainer} | select-object FullName, LastWriteTime, Length | export-csv  -path "C:\Temp\gitFileDetail.csv"