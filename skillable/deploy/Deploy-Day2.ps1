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
$templateFile = Join-Path $repositoryRoot 'customer/modernize-bootcamp/infra/main.bicep'
if (-not (Test-Path -LiteralPath $templateFile -PathType Leaf)) {
    throw "Customer deployment template not found: $templateFile"
}

Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# Leave the prefix, resource groups, and deployment dependencies to main.bicep.
$templateParameters = @{
    environmentName      = $EnvironmentName
    primaryLocation      = $PrimaryLocation
    secondaryLocation    = $SecondaryLocation
    applicationLocation  = $ApplicationLocation
    databaseMode         = 'sqlMi'
    sqlEntraAdminObjectId = $SqlEntraAdminObjectId
    sqlEntraAdminLogin    = $SqlEntraAdminLogin
    vmAdminUsername      = $VmAdminUsername
    vmAdminPassword      = $VmAdminPassword
}

$deploymentName = "$EnvironmentName-deploy"
# Emit the deployment result, including Outputs, for Skillable finalization.
New-AzSubscriptionDeployment `
    -Name $deploymentName `
    -Location $PrimaryLocation `
    -TemplateFile $templateFile `
    -TemplateParameterObject $templateParameters
