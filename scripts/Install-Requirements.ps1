[CmdletBinding()]
param(
    [switch]$CurrentUser
)

$ErrorActionPreference = 'Stop'
$scope = if ($CurrentUser) { 'CurrentUser' } else { 'AllUsers' }

$modules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Identity.SignIns'
)

foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Scope $scope -Repository PSGallery -Force -AllowClobber
    }
    else {
        Write-Host "$module is already installed."
    }
}

Write-Host 'Requirements installation complete.'
