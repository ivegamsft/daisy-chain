# sync.ps1 -- Pull the latest dAIsy Chain framework updates into a consumer repo
#
# Usage (from the root of your consumer repo):
#   $env:DAISY_REPO = 'https://github.com/IBuySpy-Shared/daisy-chain.git'; .\sync.ps1
#   $env:DAISY_REF  = 'v1.0.0'; .\sync.ps1     # pin to a release tag
#
# What this syncs (overwrites):
#   docs/factory-process/               governance docs
#   docs/architecture/migration-factory.md  C4 diagram
#   factory/stamp.ps1                   workcell stamp script
#   factory/plant.yml                   plant configuration schema
#   factory/README.md                   factory reference
#   examples/                           IBuySpy reference workflows
#
# What this does NOT touch:
#   docs/factory-state.json             your app registry (never overwritten)
#   factory/registry.yml                your stamped workcell list
#   .github/workflows/                  your CI/CD workflows
#   README.md                           your instance README

param()

$ErrorActionPreference = 'Stop'

$DaisyRepo = $env:DAISY_REPO ?? 'https://github.com/IBuySpy-Shared/daisy-chain.git'
$DaisyRef  = $env:DAISY_REF  ?? 'main'
$TempDir   = Join-Path ([System.IO.Path]::GetTempPath()) "daisy-chain-sync-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

Write-Host "Syncing dAIsy Chain framework from $DaisyRepo@$DaisyRef"

git clone --quiet --depth 1 --branch $DaisyRef $DaisyRepo $TempDir

# Sync framework directories (preserve consumer-owned files)
$SyncDirs = @('docs/factory-process', 'docs/architecture', 'examples', 'factory')
foreach ($dir in $SyncDirs) {
    $src = Join-Path $TempDir $dir
    if (Test-Path $src) {
        New-Item -ItemType Directory -Force $dir | Out-Null
        # Copy all files except consumer-owned ones
        Get-ChildItem $src -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($src.Length).TrimStart('\','/')
            # Skip files the consumer owns
            if ($rel -in @('factory-state.json', 'registry.yml')) { return }
            $dst = Join-Path $dir $rel
            New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
            Copy-Item $_.FullName $dst -Force
        }
        Write-Host "  synced $dir/"
    }
}

Remove-Item $TempDir -Recurse -Force

$OldVersion = if (Test-Path '.daisy-chain-version') { Get-Content '.daisy-chain-version' } else { 'unknown' }
$NewVersion  = (Get-Date -Format 'yyyyMMdd')
Set-Content '.daisy-chain-version' $NewVersion

Write-Host ""
Write-Host "dAIsy Chain sync complete. Version: $NewVersion (was: $OldVersion)"
Write-Host "Review changes with: git diff"
