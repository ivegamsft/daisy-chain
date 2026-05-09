# Using the dAIsy Chain Template

This guide walks you through adopting the dAIsy Chain migration factory for your own GitHub org. Following all six steps takes roughly 2–4 hours for a first app.

---

## Prerequisites

- **GitHub org** — you need admin access to create repositories and configure secrets.
- **Azure subscription** — for Plant/Cell infrastructure and Workcell app deployments.
- **Azure CLI** (`az`) — used to bootstrap OIDC federated credentials.
- **GitHub CLI** (`gh`) — used to configure secrets and manage repos.
- **PowerShell 7+** — factory scripts (`stamp.ps1`, `setup.ps1`) require PowerShell 7.
- **Basecoat** _(optional but recommended)_ — governance framework that governs all AI agents. Install via `.\setup.ps1` after repo creation. See [Basecoat](https://github.com/ivegamsft/basecoat).

---

## Step 1 — Create Your Hub Repo from This Template

1. On the [dAIsy Chain GitHub page](https://github.com/IBuySpy-Dev/app-migration-with-ai), click **"Use this template"** → **"Create a new repository"**.
2. Choose your **GitHub org** as the owner.
3. Name the repo `app-migration-with-ai` (or your preferred hub name) and set it to **Private** (recommended).
4. Click **"Create repository"**.
5. Clone locally and bootstrap Basecoat governance:

```powershell
git clone https://github.com/<your-org>/app-migration-with-ai
cd app-migration-with-ai
.\setup.ps1
```

---

## Step 2 — Configure Azure OIDC Secrets

dAIsy Chain uses OIDC federated credentials — no stored client secrets. You need three GitHub repository secrets and one Azure federated credential per environment.

### 2a. Create a Microsoft Entra app registration

```bash
az ad app create --display-name "daisy-chain-github-<your-org>"
# Note the appId (client ID) and objectId from the output
```

### 2b. Create a federated credential for the main branch

```bash
az ad app federated-credential create \
  --id <objectId> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<your-org>/app-migration-with-ai:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 2c. Assign contributor role on your subscription

```bash
az role assignment create \
  --assignee <appId> \
  --role Contributor \
  --scope /subscriptions/<your-subscription-id>
```

### 2d. Set GitHub secrets

```bash
gh secret set AZURE_CLIENT_ID      --body "<appId>"         --repo <your-org>/app-migration-with-ai
gh secret set AZURE_TENANT_ID      --body "<tenantId>"      --repo <your-org>/app-migration-with-ai
gh secret set AZURE_SUBSCRIPTION_ID --body "<subscriptionId>" --repo <your-org>/app-migration-with-ai
gh secret set SPOKE_PAT            --body "<pat-with-repo-and-workflow-scopes>" --repo <your-org>/app-migration-with-ai
```

`SPOKE_PAT` is a GitHub Personal Access Token (classic) with `repo` and `workflow` scopes. It is used by the conveyor to create and update Workcell repositories in your org.

---

## Step 3 — Update `factory/plant.yml`

Open `factory/plant.yml` and replace the placeholder values with your org and environment configuration:

```yaml
plant:
  name: <your-factory-name>   # e.g., "acme-migration-factory"
  environment: dev
  region: eastus              # Azure region for Plant infrastructure

# Canary workcell — set to the name of your first migration app
canary:
  workcell: <your-first-app>  # e.g., "legacy-portal"
  status: pending
```

Enable Cells incrementally as you provision them. Start with `identity`, then `network`. Leave all others `enabled: false` until you are ready.

Commit the updated `plant.yml`:

```powershell
git add factory/plant.yml
git commit -m "chore(factory): configure plant.yml for <your-org>"
git push
```

---

## Step 4 — Stamp Workcell Repos for Each App

Each app gets its own Workcell repository, stamped from the template in `factory/templates/`. Run `stamp.ps1` once per app:

```powershell
.\factory\stamping\stamp.ps1 `
  -OrgName     "<your-org>" `
  -AppName     "<app-name>" `         # e.g., "legacy-portal"
  -Treatment   "Rehost" `             # Rehost | Replatform | Rewrite | Retire | Reference
  -Environment "dev"
```

The script:
1. Creates `<your-org>/app-<app-name>-migration` in your GitHub org
2. Applies the Workcell template (workflows, `.intake.yml`, `docs/`)
3. Configures the same OIDC secrets (using `SPOKE_PAT`)
4. Opens an issue in the hub repo to track S1 intake

Repeat for each app in your migration portfolio.

---

## Step 5 — Register Apps in `docs/factory-state.json`

The factory tracks all apps in `docs/factory-state.json`. Add an entry for each app using the schema from `examples/`:

```json
{
  "apps": [
    {
      "name": "<app-name>",
      "workcell": "<your-org>/app-<app-name>-migration",
      "treatment": "Rehost",
      "station": "S1",
      "complexity": "LOW",
      "loc": 4000,
      "status": "in-progress"
    }
  ]
}
```

See `examples/` for reference entries and the full JSON schema. Commit after adding each app.

---

## Step 6 — Run S1 Intake Workflows and Progress Through S1→S5

### S1 — Intake

Trigger the S1 intake workflow for each Workcell. This validates the `.intake.yml` BOM against the hub schema:

```bash
gh workflow run s1-intake.yml --repo <your-org>/app-<app-name>-migration
```

### S2 — Assessment

Run the `app-inventory` Copilot agent against the legacy source to produce a dependency map and treatment recommendation. The agent outputs a complexity score and confirms or adjusts the treatment selected in Step 4.

### S3 → S5

Follow the station exit criteria in [`docs/factory-process/`](docs/factory-process/) for each station:

| Station | Exit Criteria Document |
|---|---|
| S3 Rehost | `docs/factory-process/s3-exit-criteria.md` |
| S4 Replatform / Rewrite | `docs/factory-process/s4-exit-criteria.md` |
| S5 Verify & Retire | `docs/factory-process/s5-exit-criteria.md` |

Raise an **andon** (halt-the-line alert) whenever a station is blocked — see [`docs/factory-process/andon-protocol.md`](docs/factory-process/andon-protocol.md).

---

## Factory Operations

| Reference | Purpose |
|---|---|
| [`docs/factory-process/`](docs/factory-process/) | Andon protocol, exit criteria, tag taxonomy, takt time targets |
| [`docs/migration-factory.md`](docs/migration-factory.md) | Full conveyor belt model and station details |
| [`docs/treatment-options.md`](docs/treatment-options.md) | Treatment decision matrix with effort, cost, and risk ratings |
| [`docs/guardrails/`](docs/guardrails/) | OIDC policy, secrets guardrails, CAF naming, container image tag rules |
| [`docs/architecture/`](docs/architecture/) | C4 diagrams, hub-spoke topology, cellular model |

---

## Reference Implementation

The IBuySpy migration (5 apps: Classifieds, IBuySpy, Jobs, PetShop, TimeTracker) is the reference implementation. Examine its workflow implementations as starting points:

- [`examples/workflows/ibuyspy/`](examples/workflows/ibuyspy/) — all S3–S5 deploy and infra workflows

These are ready-to-adapt examples, not production-ready templates. Adjust resource names, regions, and treatment paths for your environment.
