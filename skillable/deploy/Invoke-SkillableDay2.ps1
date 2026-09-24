<#
.SYNOPSIS
Authenticates to Azure, retrieves the public repository, and launches Day 2.
.PARAMETER RepositoryBaseUrl
Raw repository root: https://raw.githubusercontent.com/<owner>/<repo>/<ref>
Use a branch, tag, or commit SHA, without a file path. A pinned commit is recommended.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$AppId,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$AppSecret,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$EnvironmentName,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$PrimaryLocation,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$SecondaryLocation,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$ApplicationLocation,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$VmAdminUsername,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$VmAdminPassword,

    [Parameter(Mandatory)]
    [ValidateScript({
        $parsedObjectId = [guid]::Empty
        [guid]::TryParse($_, [ref]$parsedObjectId)
    })]
    [string]$SqlEntraAdminObjectId,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$SqlEntraAdminLogin,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$RepositoryBaseUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryMatch = [regex]::Match(
    $RepositoryBaseUrl,
    '^https://raw\.githubusercontent\.com/(?<owner>[A-Za-z0-9-]+)/(?<repo>[A-Za-z0-9_.-]+)/(?<ref>[^?#\s]+?)/?$'
)
if (-not $repositoryMatch.Success) {
    throw 'RepositoryBaseUrl must be https://raw.githubusercontent.com/<owner>/<repo>/<ref> with no file path, query, or fragment.'
}
$owner = $repositoryMatch.Groups['owner'].Value
$repository = $repositoryMatch.Groups['repo'].Value
$repositoryRef = [uri]::EscapeDataString(
    [uri]::UnescapeDataString($repositoryMatch.Groups['ref'].Value)
)
$archiveUrl = "https://codeload.github.com/$owner/$repository/zip/$repositoryRef"

Write-Host 'Authenticating to Azure with the service principal...'
$secureAppSecret = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
$credential = [pscredential]::new($AppId, $secureAppSecret)
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $credential -Scope Process | Out-Null
Set-AzContext -SubscriptionId $SubscriptionId -Tenant $TenantId -Scope Process | Out-Null

$currentContext = Get-AzContext

if ($null -eq $currentContext -or
    $currentContext.Subscription.Id -ne $SubscriptionId) {
    throw 'Az PowerShell subscription context does not match the requested SubscriptionId.'
}

$workingDirectory = Join-Path ([IO.Path]::GetTempPath()) ("SkillableDay2-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $workingDirectory | Out-Null
    $archivePath = Join-Path $workingDirectory 'repository.zip'
    $extractionPath = Join-Path $workingDirectory 'source'

    Write-Host 'Downloading the public repository archive...'
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath -UseBasicParsing

    Write-Host 'Extracting the repository archive...'
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractionPath
    $repositoryRoots = @(Get-ChildItem -LiteralPath $extractionPath -Directory)
    if ($repositoryRoots.Count -ne 1) {
        throw 'Expected exactly one repository root directory in the GitHub archive.'
    }
    $deploymentScript = Join-Path $repositoryRoots[0].FullName 'skillable/deploy/Deploy-Day2.ps1'
    if (-not (Test-Path -LiteralPath $deploymentScript -PathType Leaf)) {
        throw 'The downloaded repository does not contain skillable/deploy/Deploy-Day2.ps1.'
    }

    $secureVmAdminPassword = ConvertTo-SecureString `
        -String $VmAdminPassword `
        -AsPlainText `
        -Force

    $deploymentParameters = @{
        SubscriptionId       = $SubscriptionId
        EnvironmentName      = $EnvironmentName
        PrimaryLocation      = $PrimaryLocation
        SecondaryLocation    = $SecondaryLocation
        ApplicationLocation  = $ApplicationLocation
        VmAdminUsername      = $VmAdminUsername
        VmAdminPassword      = $secureVmAdminPassword
        SqlEntraAdminObjectId = $SqlEntraAdminObjectId
        SqlEntraAdminLogin    = $SqlEntraAdminLogin
    }

    Write-Host 'Starting customer deployment through Deploy-Day2.ps1...'
    & $deploymentScript @deploymentParameters
    Write-Host 'Day 2 deployment completed.'
}
finally {
    $secureAppSecret = $null
    $credential = $null
    $secureVmAdminPassword = $null

    if (Test-Path -LiteralPath $workingDirectory) {
        Remove-Item -LiteralPath $workingDirectory -Recurse -Force
    }
}
