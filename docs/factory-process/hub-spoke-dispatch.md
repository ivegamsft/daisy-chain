# Hub/Spoke Workflow Dispatch Guardrails

This document defines the rules for triggering workflows across the hub (app-migration-with-ai) and spoke (per-app workcell) repos.

## Architecture

```
Hub repo (app-migration-with-ai)
  |-- Hub workflows: validate, trigger spoke, deploy infra, run smoke test
  |
  +--[workflow_dispatch via SPOKE_PAT]--> Spoke repo (app-XXX-migration)
                                            |-- build-s5.yml: build + push image to ACR + update ACA
```

## Rules

### Rule 1: Hub controls orchestration; spoke controls build

- The **hub** initiates deployments and validates outcomes
- The **spoke** owns the build process (Dockerfile, image push, containerapp update)
- Hub workflows must NOT duplicate build steps that the spoke already performs

### Rule 2: SPOKE_PAT is required for cross-repo dispatch

To trigger `workflow_dispatch` on a spoke repo, the hub workflow must use a GitHub PAT:

```yaml
- name: Trigger spoke build
  env:
    GH_TOKEN: ${{ secrets.SPOKE_PAT }}  # NOT github.token -- that only works within the same repo
  run: |
    gh workflow run build-s5.yml --repo IBuySpy-Dev/app-petshop-migration ...
```

- `SPOKE_PAT` must be a fine-grained PAT with **Actions: Write** and **Workflows: Write** permissions
- Scope it to only the spoke repos that need it
- Hub workflows must fail fast with a clear error if `SPOKE_PAT` is not set (see `check-prerequisites` job pattern)

### Rule 3: Hub workflows must validate SPOKE_PAT before any work

All hub S5 deploy workflows follow this pattern:

```yaml
jobs:
  check-prerequisites:
    runs-on: ubuntu-latest
    steps:
      - name: Verify SPOKE_PAT secret
        run: |
          if [ -z "${{ secrets.SPOKE_PAT }}" ]; then
            echo "::error::SPOKE_PAT secret is not set. ..."
            exit 1
          fi

  build-and-push:
    needs: check-prerequisites
    ...
```

### Rule 4: Wait for spoke workflow completion before smoke testing

Hub workflows must wait for the spoke build to complete before running smoke tests:

```bash
# Trigger
gh workflow run build-s5.yml --repo $SPOKE_REPO ...
sleep 30  # allow GH to register the new run

# Get run ID
RUN_ID=$(gh run list --repo $SPOKE_REPO --workflow build-s5.yml --limit 1 --json databaseId --jq '.[0].databaseId')

# Wait (exits non-zero on failure)
gh run watch $RUN_ID --repo $SPOKE_REPO --exit-status
```

### Rule 5: Smoke tests must check response body, not just HTTP status

Azure Container Apps returns HTTP 200 for the default placeholder page. A smoke test that only checks status code is test theater:

```bash
# BAD - test theater
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")
[[ "$STATUS" == "200" ]] && echo "passed"

# GOOD - checks actual app content
BODY=$(curl -s "$APP_URL/")
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/")
if [[ "$STATUS" == "200" ]] && echo "$BODY" | grep -qi "petshop\|fish\|category"; then
  echo "[OK] App is responding with real content"
elif echo "$BODY" | grep -qi "Azure Container Apps\|Welcome to nginx"; then
  echo "::error::Default placeholder page -- app not deployed"
  exit 1
fi
```

### Rule 6: Firewall open/grant/close must happen in the same job

SQL firewall rules opened for a runner IP must be closed in the same job (`if: always()`). Runner IP changes between jobs, so opening in job A and closing in job B will fail:

```yaml
jobs:
  deploy-and-grant:  # single job for firewall lifecycle
    steps:
      - name: Add runner IP to SQL firewall
        id: fw
        run: |
          RUNNER_IP=$(curl -s https://api.ipify.org)
          az sql server firewall-rule create --name "gha-${{ github.run_id }}" ...
      
      - name: Deploy
        run: az containerapp update ...
      
      - name: Remove runner IP from SQL firewall
        if: always()  # runs even on failure
        run: |
          az sql server firewall-rule delete --name "gha-${{ github.run_id }}" ... || true
```

## Checklist for New Hub Workflow

- [ ] `check-prerequisites` job validates SPOKE_PAT
- [ ] `build-and-push` job uses `GH_TOKEN: ${{ secrets.SPOKE_PAT }}`
- [ ] Hub waits for spoke run to complete with `gh run watch --exit-status`
- [ ] Smoke test checks response body (not just HTTP status)
- [ ] Smoke test explicitly rejects ACA/nginx default pages
- [ ] SQL firewall open/grant/close in same job (if applicable)
- [ ] Concurrency group prevents parallel runs: `group: deploy-APP-ENV`

## Related Docs
- [Andon Protocol](./andon-protocol.md)
- [Station Exit Criteria](./station-exit-criteria.md)
