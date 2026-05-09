# Azure Tag Taxonomy

All Azure resources provisioned by the dAIsy Chain factory **must** carry the following tags. Tags are enforced via Bicep parameter files and validated by the `validate-caf-naming.yml` reusable workflow.

## Required Tags

| Tag Key | Example Value | Description |
|---------|---------------|-------------|
| `factory` | `daisy-chain` | Factory identifier -- always `daisy-chain` |
| `app` | `petshop` | Short app slug matching the `name` field in `factory-state.json` |
| `env` | `dev` | Deployment environment: `dev`, `staging`, or `prod` |
| `station` | `S5` | Factory station that provisioned this resource: S1-S5 |
| `treatment` | `Replatform` | Treatment applied: Rehost, Replatform, Rewrite, Retire, or Reference |
| `managed-by` | `bicep` | IaC tool: `bicep`, `terraform`, or `manual` |
| `workcell` | `IBuySpy-Dev/app-petshop-migration` | Spoke repo full name |

## Optional Tags

| Tag Key | Example Value | Description |
|---------|---------------|-------------|
| `sprint` | `S17` | Factory sprint when resource was created |
| `owner` | `team-platform` | Team or individual responsible for the app |
| `cost-center` | `cc-migration-001` | For chargeback / cost allocation |

## Tag Value Rules

- All tag values: lowercase, kebab-case where applicable
- `factory`: always `daisy-chain` (never DAISY-CHAIN, never "dAIsy Chain")
- `app`: must exactly match the `name` field in `factory-state.json`
- `env`: one of `dev`, `staging`, `prod` (no abbreviations)
- `station`: one of `S1`, `S2`, `S3`, `S4`, `S5` (uppercase S + digit)
- `treatment`: one of `Rehost`, `Replatform`, `Rewrite`, `Retire`, `Reference` (title case)

## Bicep Implementation

Tags are defined in each app's Bicep parameter file and passed through as an object:

```bicep
param tags object = {
  factory: 'daisy-chain'
  app: 'petshop'
  env: 'dev'
  station: 'S5'
  treatment: 'Replatform'
  'managed-by': 'bicep'
  workcell: 'IBuySpy-Dev/app-petshop-migration'
}
```

Apply to every resource:
```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-petshop-dev'
  location: location
  tags: tags
  // ...
}
```

## Validation

The `validate-caf-naming.yml` reusable workflow validates:
1. Resource group has all required tags
2. Tag values follow the rules above (env is one of dev/staging/prod, etc.)

Missing or invalid tags fail the pre-deploy gate and block the deployment job.

## Audit Query (Azure Resource Graph)

```kql
Resources
| where tags['factory'] == 'daisy-chain'
| project name, type, resourceGroup, tags
| extend app = tags['app'], env = tags['env'], station = tags['station']
| summarize count() by app, env, station, type
| order by app, station asc
```

Run via Azure CLI:
```bash
az graph query -q "Resources | where tags['factory'] == 'daisy-chain' | project name, type, tags | order by name asc"
```
