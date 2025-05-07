# Function to write output in green
function Write-Green {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Green
}

# Connect to Microsoft Graph with the required scopes using Device Code
Connect-MgGraph -DeviceCode -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"

# Function to get user object ID and display name from authentication email
function Get-UserDetails {
    param (
        [string]$AuthenticationEmail
    )
    $user = Get-MgUser -Filter "userPrincipalName eq '$AuthenticationEmail'"
    return @{ Id = $user.Id; DisplayName = $user.DisplayName; Email = $user.UserPrincipalName }
}

# Function to get group object ID and display name from group name
function Get-GroupDetails {
    param (
        [string]$GroupName
    )
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
    return @{ Id = $group.Id; DisplayName = $group.DisplayName }
}

# Function to add user to group
function Add-UserToGroup {
    param (
        [string]$UserObjectId,
        [string]$GroupObjectId,
        [string]$UserDisplayName,
        [string]$UserEmail,
        [string]$GroupDisplayName
    )
    try {
        New-MgGroupMember -GroupId $GroupObjectId -DirectoryObjectId $UserObjectId
        Write-Green "Added user $UserDisplayName ($UserEmail) to group $GroupDisplayName"
        return "Added Successfully"
    } catch {
        Write-Host "Failed to add user $UserDisplayName ($UserEmail) to group $GroupDisplayName" -ForegroundColor Red
        return "Failed to Add"
    }
}

# Prompt for CSV file path, use default if not provided
$csvPath = Read-Host "Enter the path to the CSV file (default: .\users.csv)"
if ([string]::IsNullOrEmpty($csvPath)) {
    $csvPath = ".\users.csv"
}

# Check if the file exists
if (-Not (Test-Path $csvPath)) {
    Write-Host "File $csvPath does not exist." -ForegroundColor Red
    exit
}

# Initialize the report data list
$reportData = @()
$reportData += "User DisplayName,User Email,Group DisplayName,Status"

# Read the CSV file
$csv = Import-Csv -Path $csvPath

foreach ($row in $csv) {
    $authenticationEmail = $row.'Authentication Email'
    $groupName = $row.'Security Group'
    
    $userDetails = Get-UserDetails -AuthenticationEmail $authenticationEmail
    $groupDetails = Get-GroupDetails -GroupName $groupName
    
    $status = Add-UserToGroup -UserObjectId $userDetails.Id -GroupObjectId $groupDetails.Id -UserDisplayName $userDetails.DisplayName -UserEmail $userDetails.Email -GroupDisplayName $groupDetails.DisplayName
    
    # Append the data to the report list
    $reportData += "$($userDetails.DisplayName),$($userDetails.Email),$($groupDetails.DisplayName),$status"
}

# Save the report data to a CSV file
$reportPath = ".\user_group_report.csv"
$reportData | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "Report generated successfully and saved as user_group_report.csv." -ForegroundColor Green
