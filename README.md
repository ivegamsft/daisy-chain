# dAIsy Chain — AI-Native Migration Factory

> **dAIsy Chain** is a reusable GitHub template for running an **AI-native migration factory** that modernizes legacy applications using GitHub Copilot agents. It implements a hub-and-spoke topology: this hub repo governs the factory; per-app **Workcell** repositories do the migration work.

Want to adopt this for your org? → **[USING_THIS_TEMPLATE.md](USING_THIS_TEMPLATE.md)**

---

## What is dAIsy Chain?

dAIsy Chain is a structured factory pattern for migrating legacy apps (ASP.NET, Classic ASP, SharePoint, MVC, etc.) to the cloud. Apps flow through five stations on a conveyor belt — from inventory through treatment selection, baseline deployment, modernization, and final cutover. GitHub Copilot agents automate the repetitive steps at each station.

**Key concepts:**

| Term | Meaning |
|---|---|
| **Station (S1–S5)** | Migration stage: Intake → Assessment → Rehost → Replatform/Rewrite → Verify & Retire |
| **Treatment** | Per-app modernization decision: Rehost · Replatform · Rewrite · Retire · Reference |
| **Workcell** | A per-app repository stamped from the factory template |
| **Plant** | One region × environment deployment of the shared infrastructure |
| **Cell** | Specialized shared-service hub (network, observability, data, identity, compliance) |
| **Conveyor** | Push-down sync + andon listener that flows patterns to Workcells and status back |
| **Andon** | Halt-the-line alert raised when a station is blocked |
| **Takt time** | Target dwell time at each Station |
| **BOM** | Bill of Materials — contract a Workcell publishes describing which Cells it consumes |

**Treatment vocabulary:**

| Treatment | Description | Target |
|---|---|---|
| **Rehost** | Lift-and-shift, zero code changes | Azure VM |
| **Replatform** | Move to managed PaaS, minimal changes | Azure App Service (Windows) |
| **Rewrite** | Rebuild cloud-native on current runtime | Azure Container Apps / App Service (Linux) |
| **Retire** | Decommission — app is obsolete | N/A |
| **Reference** | Already modern; document as target-state pattern | Archive |

Workcell repos are stamped per-app using `factory/stamping/stamp.ps1`. Each repo follows an identical layout governed by the Basecoat agent catalog pushed down from this hub.

See [examples/workflows/ibuyspy/](examples/workflows/ibuyspy/) for reference workflow implementations from the IBuySpy migration.

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                   dAIsy Chain Hub  (this repo, Tier 0)             │
│       tenant • policy • billing • OIDC trust • agent catalog       │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
        ┌──────────────┐              ┌──────────────┐
        │   PLANT      │              │   PLANT      │     Tier 1
        │  <region>-dev│              │<region>-prod │     region × env
        └──────┬───────┘              └──────┬───────┘
               │                             │
   ┌───────────┴───────────┐     ┌───────────┴───────────┐
   │ Cells (Tier 2):       │     │ Cells (Tier 2):       │   shared infra
   │  • cell-network       │     │  • cell-network       │
   │  • cell-observability │     │  • cell-observability │
   │  • cell-data          │     │  • cell-data          │
   │  • cell-identity      │     │  • cell-identity      │
   │  • cell-compliance    │     │  • cell-compliance    │
   └───────────┬───────────┘     └───────────┴───────────┘
               │ kit (resource IDs)
               ▼
       Workcells (Tier 3 — one repo per app, stamped from template)
        ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  app-1   │  │  app-2   │  │  app-3   │  │   ...    │
        └──────────┘  └──────────┘  └──────────┘  └──────────┘
```

Manufacturing terms — see the glossary in [ADR-011](docs/adrs/ADR-011-Cellular-Hub-architecture.md).

Full architecture documentation: [`docs/architecture/migration-factory.md`](docs/architecture/migration-factory.md)

---

## Quick Start

New to dAIsy Chain? Follow **[USING_THIS_TEMPLATE.md](USING_THIS_TEMPLATE.md)** — a 6-step guide covering:

1. Use the GitHub "Use this template" button to create your hub repo
2. Configure Azure OIDC secrets
3. Update `factory/plant.yml` with your org and app registry
4. Stamp Workcell repos for each app
5. Register apps in `docs/factory-state.json`
6. Run S1 intake workflows and progress through S1→S5

---

## Factory Process (S1–S5)

| Station | Name | What Happens |
|---|---|---|
| **S1** | Intake | App registered; intake YAML created; Workcell stamped |
| **S2** | Assessment | `app-inventory` agent scans source; treatment decided (Rehost/Replatform/Rewrite/Retire/Reference) |
| **S3** | Rehost | App deployed to Azure VM; smoke tests establish baseline; S3 exit criteria met |
| **S4** | Replatform / Rewrite | Move to App Service (Replatform) or rebuild on .NET 8 (Rewrite); side-by-side traffic split |
| **S5** | Verify & Retire | Drift monitoring; 100% cutover; legacy decommissioned |

Full process details: [`docs/migration-factory.md`](docs/migration-factory.md)

---

## Key Documentation

| Document | Description |
|---|---|
| [`docs/factory-process/`](docs/factory-process/) | Station exit criteria, andon protocol, tag taxonomy, takt time targets |
| [`docs/architecture/`](docs/architecture/) | C4 diagrams, hub-spoke topology, migration phases, cellular model |
| [`docs/guardrails/`](docs/guardrails/) | OIDC federation, secrets policy, CAF naming, container image tags |
| [`docs/adrs/`](docs/adrs/) | Architecture Decision Records (ADR-001 through ADR-011+) |
| [`docs/treatment-options.md`](docs/treatment-options.md) | Treatment tier analysis: Rehost, Replatform, Rewrite, Retire, Reference |
| [`factory/plant.yml`](factory/plant.yml) | Cell inventory and deployment schedule |
| [`examples/workflows/ibuyspy/`](examples/workflows/ibuyspy/) | Reference workflow implementations |

---

## Dashboard

The **shop floor dashboard** is published via GitHub Pages and shows live station status across all Workcells. Validate it by running the `factory-app-pages.yml` workflow.

---

## Repo Layout

```
.github/workflows/      Factory-tier workflows (dashboard, conveyor, andon)
docs/
  adrs/                 Architecture Decision Records
  architecture/         C4 diagrams, hub-spoke topology, migration phases
  factory-process/      Station exit criteria, andon protocol, tag taxonomy
  guardrails/           OIDC, secrets, CAF naming, container image tags
factory/
  plant.yml             Plant config — org name, cell enable flags
  registry.yml          Cell type registry
  stamping/             stamp.ps1 — Workcell repo stamping automation
  intake/               BOM JSON Schema (validates spoke .intake.yml#bom)
  conveyor/             Sync, andon listener, status rollup scripts
  templates/            Workcell repo template (stamped per app)
examples/
  workflows/ibuyspy/    Reference workflow implementations (IBuySpy migration)
infra/
  cells/                Per-Cell deployable Bicep
  modules/              Shared Bicep modules (used by all Cells + Workcells)
TREATMENT_MATRIX.md     Per-app treatment tier decision matrix
setup.ps1 / sync.ps1    Bootstrap and upgrade the Basecoat governance framework
```

---

## What Lives Here vs. in a Workcell

| Concern | dAIsy Chain Hub | Workcell |
|---|---|---|
| Tenant / subscription / policy | ✅ | — |
| Plant + Cell Bicep | ✅ | — |
| Agent / instruction / skill catalog | ✅ (pushed down) | consumed via sync |
| BOM schema | ✅ (authoritative) | consumed via sync |
| Workcell template | ✅ | — |
| App source code | — | ✅ |
| App-specific infra | — | ✅ |
| App deploy workflows | — | ✅ |
| `.intake.yml` (BOM) | — | ✅ |

If you find application source, per-app infra, or per-app deploy workflows in this hub repo, **that is a bug**. File an issue labeled `cleanup`.

---

## Setup

```powershell
# Pull the Basecoat governance framework
.\setup.ps1

# Upgrade Basecoat
$env:BASECOAT_REF = "v3.11.0"
.\sync.ps1
```

---

## Governance (mandatory)

Governed by [Basecoat](https://github.com/ivegamsft/basecoat). Rules from `.basecoat/governance.instructions.md`:

1. **Issue-first** — every change references an issue.
2. **PRs only** — never push to `main`.
3. **No secrets** — never commit credentials, tokens, PII, or internal URLs.
4. **Branch naming** — `<type>/<issue>-<short-description>` (`feat`, `fix`, `docs`, `chore`, `security`).
5. **Commit format** — `<type>(<scope>): <summary> (#<issue>)`.
6. **OIDC only** — no Azure client secrets in workflows.

PR description must include: Summary, Validation, Issue Reference (`closes #N`), Risk + rollback.

---

## Naming

- Files / folders: `kebab-case`
- Types / classes: `PascalCase`
- Variables / functions: `camelCase`
- Azure resources: `<org>-<workload>-<env>-<region>-<suffix>` (CAF)

---

## Reference ADRs

- [ADR-009](docs/adrs/ADR-009-thin-hub-multi-mode-intake.md) — thin hub with multi-mode intake
- [ADR-010](docs/adrs/ADR-010-SQL-Private-Endpoint.md) — SQL private endpoint per Workcell
- [ADR-011](docs/adrs/ADR-011-Cellular-Hub-architecture.md) — cellular manufacturing hub topology
- [TREATMENT_MATRIX.md](TREATMENT_MATRIX.md) — per-app treatment tier decision matrix
- [`docs/guardrails/`](docs/guardrails/) — OIDC, secrets, naming, container tags, env-example, DB concurrency
