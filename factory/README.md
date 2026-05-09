# Migration Factory — How It Works

> The factory is a repeatable conveyor belt: any legacy ASP.NET app goes in one end and a cloud-native app comes out the other.

## Factory Pipeline

```
Legacy App (IIS/Windows)
        │
        ▼
  ┌─────────────┐
  │  S2 Inventory│  ← app-inventory agent scans web.config, packages.config, SQL schema
  └──────┬──────┘
         │
         ▼
  ┌──────────────────┐
  │ S2 
  │    Selection     │
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ S3 Baseline      │  ← deploy to Azure VM, run smoke tests, capture metrics
  │    + Tests       │
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ S4 Modernize     │  ← code-modernizer + Copilot, side-by-side deploy, traffic split
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ S5 Verify +      │  ← drift-monitor, 100% cutover, decommission legacy
  │    Cutover       │
  └──────┬───────────┘
         │
         ▼
  Cloud App (Azure)
```

## Factory Structure (Phase 2 Reorganization)

```
factory/
├── dAIsy Chain/              ← Tier-0 Bicep (tenant policies, root RG taxonomy, OIDC trust roots)
├── plant/                ← Tier-1 Bicep (per-region/env Plant scaffolding)
├── conveyor/             ← Orchestration: sync, andon listener, status rollup
│   ├── basecoat/         ← setup.ps1, sync.ps1 (moved from root)
│   └── scripts/          ← Conveyor automation scripts
├── stamping/             ← Stamp pattern (Phase 5 placeholder)
├── intake/               ← BOM intake validation workflow (.intake.yml format)
├── iac-modules/          ← Reusable Bicep modules and utilities
├── templates/            ← Bicep templates and parameter files
├── squads/               ← Squad-specific configurations (per-app deployments)
├── workcell-bootstrap/   ← Per-app + per-env bootstrap (moved from bootstrap/)
├── scripts/              ← Factory utility scripts
├── plant.yml             ← Cell inventory and manufacturing schedule
└── registry.yml          ← Cell type registry
```

## Shared Tooling (`factory/conveyor/scripts/`)

| Script / Tool | Purpose |
|---------------|---------|
| `inventory.ps1` | Scan IIS site, web.config, packages — output dependency JSON |
| `deploy-to-vm.ps1` | Idempotent VM deployment for legacy app |
| `run-smoke-tests.ps1` | Happy-path smoke test runner |
| `deploy-modern.ps1` | Modern app deployment (App Service / AKS) |
| `split-traffic.ps1` | Configure Azure Front Door traffic weight |

All scripts are parameterized by `$AppName` — run the same script for any of the 5 apps.

## Tier-0 & Tier-1 Bicep

- **Tier-0** (`factory/dAIsy Chain/`): Tenant-level policies, root resource group taxonomy, OIDC trust roots
- **Tier-1** (`factory/plant/`): Per-region and per-environment Plant scaffolding
- **Modules** (`factory/iac-modules/`): Reusable Bicep modules (VNets, NSGs, Key Vaults, SQL, etc.)
- **Templates** (`factory/templates/`): Ready-to-use template combinations

## Basecoat Agents

| Agent | Role | Sprint | Definition |
|-------|------|--------|------------|
| `app-inventory` | Scans legacy app, outputs dependency map | S2 | [app-inventory.agent.md](../.github/agents/app-inventory.agent.md) |
| `migration-advisor` | Recommends treatment based on inventory | S2 | [migration-advisor.agent.md](../.github/agents/migration-advisor.agent.md) |
| `code-modernizer` | Suggests .NET migration paths with Copilot | S4 | _(planned)_ |
| `container-generator` | Generates Dockerfiles (Windows/Linux) | S4 | _(planned)_ |
| `drift-monitor` | Compares legacy vs modern, alerts on divergence | S5 | _(planned)_ |

## Running the Factory

```powershell
# S2 - Inventory an app
.\factory\scripts\inventory.ps1 -AppName classifieds -SourcePath apps\classifieds\legacy

# S3 - Deploy to baseline VM
.\factory\scripts\deploy-to-vm.ps1 -AppName classifieds -ResourceGroup rg-migration-dev

# S3 - Run smoke tests
.\factory\scripts\run-smoke-tests.ps1 -AppName classifieds -BaseUrl https://classifieds.example.com

# S4 - Deploy modern version
.\factory\scripts\deploy-modern.ps1 -AppName classifieds -Target AppService

# S5 - Split traffic
.\factory\scripts\split-traffic.ps1 -AppName classifieds -ModernPercent 10
```

## References

- [docs/architecture.md](../docs/architecture.md) — Strangler Fig pattern diagrams
- [docs/treatment-options.md](../docs/treatment-options.md) — Treatment tier analysis
- [docs/sprint-plan.md](../docs/sprint-plan.md) — Full sprint plan
