# Station Exit Criteria

Each station (S1-S5) has explicit **green tag** (pass) and **red tag** (fail/block) criteria. An app cannot advance to the next station unless all green-tag criteria are met. A red tag halts progression and may trigger an andon pull.

## S1 -- Intake & Inventory

### Green Tag (pass)
- [ ] App registered in `factory-state.json` with name, spokeRepo, stack, complexity
- [ ] Treatment recommendation recorded in `treatmentOptions`
- [ ] Workcell (spoke repo) created under the factory org
- [ ] App stamped into workcell via `stamp.ps1`
- [ ] `factory-state.json` entry has `currentStation: S1`, `stations.S1: done`

### Red Tag (block)
- Source code not available or cannot be retrieved
- No viable treatment option (candidate for Retire)
- Spoke repo creation blocked (org quota, billing)

---

## S2 -- Assessment & Planning

### Green Tag (pass)
- [ ] Architecture documented: tech stack, dependencies, data stores
- [ ] Risks identified and rated (HIGH/MED/LOW)
- [ ] Treatment option selected and rationale recorded in `inventory.treatmentRationale`
- [ ] Sprint plan drafted in workcell repo
- [ ] `stations.S2: done`

### Red Tag (block)
- No access to runtime/database to assess dependencies
- Regulatory/legal blocker on data migration
- Treatment path technically infeasible (escalate to architect)

---

## S3 -- Treatment Execution (varies by treatment)

### Green Tag (Rehost)
- [ ] IIS VM provisioned in Azure (Bicep/ARM deployed)
- [ ] App files deployed and IIS site configured
- [ ] App responds to HTTP on deployed VM URL
- [ ] `stations.S3: done`

### Green Tag (Replatform)
- [ ] App Service or ACA provisioned
- [ ] App deployed and health probe returns HTTP 200
- [ ] Config (connection strings, secrets) migrated to Key Vault
- [ ] `stations.S3: done`

### Green Tag (Rewrite)
- [ ] Target framework agreed and scaffolded
- [ ] Functional parity baseline documented
- [ ] Core domain logic ported and unit tested
- [ ] `stations.S3: done`

### Green Tag (Reference / Archive)
- [ ] Source preserved in workcell with README explaining status
- [ ] Entry marked `factoryStatus: complete` in factory-state.json
- [ ] `stations.S3: done`

### Red Tag (any treatment)
- Deployment fails 3+ times with same root cause (pull andon)
- Critical dependency unavailable in Azure region
- License or IP blocker on code migration

---

## S4 -- Validation & Testing

### Green Tag (pass)
- [ ] Smoke test passes: HTTP 200 with **app-specific body content** (not default page)
- [ ] Health probe `/healthz/ready` returns 200 (if applicable)
- [ ] DB connectivity verified (not just health probe -- actual query)
- [ ] No critical security findings from SAST scan
- [ ] Performance baseline within 2x of source system
- [ ] `stations.S4: done`

### Red Tag (block)
- Smoke test fails or returns ACA/IIS/nginx default page
- SQL auth error (MI roles not granted, ServiceLinker misconfigured)
- SAST scan finds HIGH severity finding (CVE, secret exposure)
- Performance regression > 5x baseline

---

## S5 -- Production Readiness

### Green Tag (pass)
- [ ] `azureUrl` recorded in `factory-state.json` and publicly reachable
- [ ] Azure resources tagged with taxonomy (factory, station, env, app)
- [ ] Deployment workflow runs green end-to-end (no manual steps)
- [ ] Smoke test validates real app content at `azureUrl`
- [ ] Runbook documented in workcell repo
- [ ] `stations.S5: done`
- [ ] `factoryStatus: complete`

### Red Tag (block)
- `azureUrl` unreachable or returns default/error page
- Missing required Azure tags (taxonomy enforcement)
- Deployment workflow requires manual secret injection each run
- No runbook documented

---

## Advancement Gate

```
S1 green -> S2 green -> S3 green -> S4 green -> S5 green -> COMPLETE
                                                         \-> blocked (andon)
```

The factory conveyor (`andon-listener.ps1`) polls for andon labels and halts station advancement for blocked apps. The factory dashboard reflects the current gate status via `factory-state.json`.

## Related Docs
- [Andon Protocol](./andon-protocol.md)
- [Treatment Options](../treatment-options.md)
- [Tag Taxonomy](./tag-taxonomy.md)
