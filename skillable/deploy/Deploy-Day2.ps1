[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$SubscriptionId,

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
    [securestring]$VmAdminPassword,

    [Parameter(Mandatory)]
    [ValidateScript({
        $parsedObjectId = [guid]::Empty
        [guid]::TryParse($_, [ref]$parsedObjectId)
    })]
    [string]$SqlEntraAdminObjectId,

    [Parameter(Mandatory)]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string]$SqlEntraAdminLogin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The Cloud Platform LCA handles Azure authentication and Skillable variable
# resolution before invoking this wrapper with concrete parameter values.
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$customerScript = Join-Path $repositoryRoot 'customer/modernize-bootcamp/infra/Deploy-Lab04.ps1'
if (-not (Test-Path -LiteralPath $customerScript -PathType Leaf)) {
    throw "Customer deployment script not found: $customerScript"
}

# Leave Prefix and all deployment sequencing to the customer-owned entry point.
$deploymentParameters = @{
    SubscriptionId       = $SubscriptionId
    EnvironmentName      = $EnvironmentName
    PrimaryLocation      = $PrimaryLocation
    SecondaryLocation    = $SecondaryLocation
    ApplicationLocation  = $ApplicationLocation
    DatabaseMode         = 'sqlMi'
    ConfirmSqlMiCost     = $true
    Action               = 'Deploy'
    VmAdminUsername      = $VmAdminUsername
    VmAdminPassword      = $VmAdminPassword
    SqlEntraAdminObjectId = $SqlEntraAdminObjectId
    SqlEntraAdminLogin    = $SqlEntraAdminLogin
}

& $customerScript @deploymentParameters
