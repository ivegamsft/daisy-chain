# Contributing to dAIsy Chain

> This repo follows [Basecoat governance](.basecoat/governance.instructions.md). The short version is below.

## Prerequisites

- **GitHub account** with access to your org's `app-migration-with-ai` hub repo.
- **GitHub CLI** (`gh`) authenticated to your org.
- **PowerShell 7+** for factory scripts.

```powershell
# Authenticate with your org
gh auth login

# Verify
gh auth status
```

## Worktree Setup for Parallel Work

When running multiple workstreams in parallel, use git worktrees to avoid conflicts:

```powershell
# Create a worktree for your branch
git worktree add ..\worktrees\<branch-name> -b <branch-name>
cd ..\worktrees\<branch-name>

# When done, remove the worktree
cd F:\Git\app-migration-with-ai
git worktree remove ..\worktrees\<branch-name> --force
```

## Golden Rules

1. **Issue first** — Log a GitHub issue BEFORE making any change
2. **PRs only** — Never commit directly to `main`
3. **No secrets** — Never commit credentials, keys, connection strings, or tenant/client IDs
4. **Kebab-case** — All file and folder names use kebab-case

## Workflow

### 1. Log an issue

Before starting any work:

```
gh issue create --title "feat: <what you're building>" --body "<why>"
```

Label it with the appropriate station (`station:s1` through `station:s5`) and your app name.

### 2. Create a branch

```
git checkout main
git pull origin main
git checkout -b feat/<issue-number>-<short-description>
```

Branch naming:
- `feat/<n>-description` — new capability
- `fix/<n>-description` — bug fix
- `docs/<n>-description` — documentation only
- `chore/<n>-description` — maintenance (deps, CI, etc.)

### 3. Make your changes

- Write code, scripts, or docs
- Keep changes focused on the issue scope
- Add `.gitkeep` to any new empty directory so it's tracked

### 4. Commit with issue reference

```
git commit -m "feat(<scope>): <short description> (#<n>)"
```

Commit types: `feat`, `fix`, `docs`, `chore`, `security`

First line ≤ 72 characters. Never include secrets, tokens, or PII in commit messages.

### 5. Push and open a PR (squash merge)

```
git push origin feat/<n>-description
gh pr create --title "feat(<scope>): <description> (#<n>)" --body "Closes #<n>"
```

PRs must:
- Reference the issue (`Closes #N`)
- Pass CI checks
- Include: Summary, Validation, Issue Reference, Risk + rollback
- Not contain any secrets

Merge strategy: **squash merge** — keeps main history linear. Delete branch after merge.

## Validating the Dashboard

The factory workflows _are_ the tests. To validate the shop floor dashboard:

```bash
gh workflow run factory-app-pages.yml
```

This regenerates the GitHub Pages dashboard from current factory state. A green run confirms the dashboard pipeline is healthy.

## Secret Handling

**Never** commit:
- Connection strings
- Client IDs / Tenant IDs
- Passwords, API keys, SAS tokens
- Certificates or private keys

Use placeholders: `<your-connection-string-here>`, `<your-tenant-id>`, etc.

For runtime secrets: use Azure Key Vault references or GitHub Actions secrets via `${{ secrets.SECRET_NAME }}`.

## Adding a New App

1. Log an issue
2. Run `factory/stamping/stamp.ps1` to create the Workcell repo
3. Add the app entry to `docs/factory-state.json`
4. Trigger the S1 intake workflow in the Workcell

See [USING_THIS_TEMPLATE.md](USING_THIS_TEMPLATE.md) for the full onboarding sequence.

## Updating Basecoat

See [.basecoat/BASECOAT_VERSION.md](.basecoat/BASECOAT_VERSION.md) for the upgrade process.
