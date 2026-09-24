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

The Cloud Platform LCA must handle Azure authentication and Skillable variable resolution before invoking the wrapper. The wrapper requires subscription, environment, location, VM administrator (with a SecureString password), and SQL Entra administrator values.

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
