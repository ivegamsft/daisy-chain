# Andon Protocol

The dAIsy Chain factory adopts the Toyota Production System "andon cord" concept: any team member (human or AI agent) can halt the production line when a defect is detected. This document defines when, how, and how to resolve andon pulls.

## When to Pull the Andon

Pull the andon when **forward progress is blocked** and cannot be unblocked within the current work session:

| Trigger | Examples |
|---------|----------|
| Azure resource misconfiguration requiring elevated access | Wrong MI principal, missing role assignment, ServiceLinker bug |
| Spoke repo missing required workflow or Dockerfile | `build-s5.yml` not present, containerization not started |
| Secret/credential missing from repo or environment | `SPOKE_PAT` not set, Key Vault empty |
| Repeated CI failures with no viable self-service fix | 10+ workflow failures on same root cause |
| Breaking change in upstream dependency requiring team decision | Azure API deprecation, SDK breaking change |
| Security finding that must not be self-resolved | Credential exposure, data exfiltration risk |

**Do NOT pull** for transient issues (flaky network, rate limits) or issues you can fix in the same session.

## How to Pull the Andon

1. **Log an issue** in the **hub repo** (`app-migration-with-ai`) with:
   - Label: `andon` + `blocked`
   - Title format: `andon(APP-STATION): Short symptom -- root cause`
   - Body must include:
     - **Symptom** -- what the user/monitor sees
     - **Root cause** -- confirmed or suspected
     - **Evidence** -- workflow run link, log snippet, or curl output
     - **Unblock path** -- exact steps a human needs to take
     - **Impact** -- which other apps/stations are affected

2. **Update `factory-state.json`**:
   - Set `factoryStatus` to `"blocked"` for the app
   - Add andon note to `notes` field

3. **Stop autonomous work** on that station. Do not attempt workarounds that mask the root cause.

### Issue Template

```markdown
## Andon Cord Pulled -- APP Station S#

### Symptom
[What the user/monitor sees]

### Root Cause
[Confirmed or suspected cause]

### Evidence
- Workflow run: [link]
- Error log: [snippet]

### Unblock Path
1. [Exact step a human must take]
2. [Second step if needed]

### Impact
- Blocks: [list of dependent work]
- Affected apps: [list]
```

## Resolving an Andon

The andon is resolved when:

1. A human (or authorized agent) completes the **unblock path** steps
2. The previously-failing workflow runs successfully
3. The smoke test passes (body-content check, not just HTTP 200)

To close the andon:
1. Add a resolution comment to the hub issue with evidence (workflow run link, curl output)
2. Update `factory-state.json`: set `factoryStatus` back to `"in-progress"` or `"complete"`
3. Close the hub issue with label `resolved`
4. Update spoke repo if applicable

## Andon Escalation Matrix

| Duration Blocked | Action |
|-----------------|--------|
| < 1 session | Self-resolve if possible; pull only if giving up |
| 1-3 sessions | Pull andon, log issue, notify team async |
| > 3 sessions | Escalate to factory architect; consider treatment change |
| > 1 sprint | Re-assess treatment option (e.g., Rehost -> Retire) |

## Active Andons

See [open issues with `andon` label](https://github.com/IBuySpy-Dev/app-migration-with-ai/issues?q=is%3Aopen+label%3Aandon) for current production stops.
