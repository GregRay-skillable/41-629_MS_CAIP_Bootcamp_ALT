# Skillable Integration Repository for Microsoft CAIP Azure Modernize Bootcamp Day 2

This repository is the Skillable integration repository for the Microsoft CAIP Azure Modernize Bootcamp Day 2 environment.

The customer deployment source is intended to remain authoritative for the Azure architecture, deployment structure, naming conventions, parameters, and deployment flow. Skillable automation in this repository should adapt to the customer deployment rather than recreate or replace it.

This structure is intended to support a later move into a private organization repository with minimal changes.

## Repository layout

### `/customer/modernize-bootcamp/`

Contains the customer-provided Azure Modernize Bootcamp deployment source. Files in this area should remain as close to upstream as possible, and Skillable-specific automation should not be mixed into them unless there is no practical alternative.

Imported from `Azure-Samples/modernize-bootcamp` at pinned commit `a97a829e37a44ae95d4aea48ad1f173836e2777d`, path `skillable/day_2/bootcamp_deployment/`. `customer/modernize-bootcamp` is intended to remain unchanged unless explicitly required.

### `/skillable/deploy/`

`skillable/deploy/Deploy-Day2.ps1` is a thin Skillable adapter that invokes the customer-owned `customer/modernize-bootcamp/infra/Deploy-Lab04.ps1` for a SQL Managed Instance deployment. It leaves the customer's prefix and deployment flow authoritative.

`skillable/deploy/Invoke-SkillableDay2.ps1` is the Skillable Cloud Platform launcher that authenticates to Azure, retrieves the repository, and invokes `Deploy-Day2.ps1`. Paste it into, or invoke it from, an Execute Script in Cloud Platform LCA after resolving Skillable variables to concrete parameter values.

The launcher requires `SubscriptionId`, `TenantId`, `AppId`, `AppSecret`, `EnvironmentName`, `PrimaryLocation`, `SecondaryLocation`, `ApplicationLocation`, `VmAdminUsername`, `VmAdminPassword`, `SqlEntraAdminObjectId`, `SqlEntraAdminLogin`, and `RepositoryBaseUrl`. It converts the supplied secret and VM password strings to SecureString values and does not set a prefix or deployment defaults.

`RepositoryBaseUrl` must be the public raw GitHub repository root in the form `https://raw.githubusercontent.com/<owner>/<repo>/<ref>` (an optional trailing slash is accepted), without a file path, query, or fragment. The ref may be a branch (including slash-containing names), tag, or commit SHA; use a trusted, pinned commit SHA for reproducible execution. The launcher downloads the corresponding complete ZIP from `codeload.github.com`, preserves relative paths, and removes its temporary files in a `finally` block. No GitHub authentication is implemented.

The runtime needs PowerShell, `Az.Accounts`, and the customer deployment's Azure CLI/Bicep prerequisites, plus access to GitHub's archive endpoint and Azure. **Azure PowerShell authentication does not authenticate Azure CLI:** the LCA must also provide an authenticated Azure CLI session for the target tenant/subscription because the unchanged customer script uses `az`. The customer's deployment confirmation behavior is unchanged.

Alternatively, an already-authenticated LCA can invoke `Deploy-Day2.ps1` directly with subscription, environment, location, VM administrator (with a SecureString password), and SQL Entra administrator values.

### `/skillable/finalize/`

Contains post-deployment Skillable configuration scripts. Expected future responsibilities include:

- User1 Azure RBAC
- Key Vault access
- SQL Managed Instance Entra configuration
- Front Door Private Link approval
- other Skillable-specific finalization

### `/skillable/validate/`

Contains smoke tests and deployment validation for the Skillable environment.

### `/docs/`

Contains implementation notes, architecture mapping, troubleshooting notes, and Skillable integration documentation.

## Guidance

- Keep the customer deployment authoritative for Azure architecture decisions.
- Prefer adapting Skillable automation to the customer deployment instead of translating the customer deployment into a separate implementation.
- Do not commit secrets, credentials, tokens, AppIds, AppSecrets, tenant-specific values, or any other sensitive information.
