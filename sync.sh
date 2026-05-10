#!/usr/bin/env bash
# sync.sh -- Pull the latest dAIsy Chain framework updates into a consumer repo
#
# Usage (from the root of your consumer repo):
#   DAISY_REPO=https://github.com/ivegamsft/daisy-chain.git ./sync.sh
#   DAISY_REF=v1.0.0 ./sync.sh          # pin to a release tag
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

set -euo pipefail

DAISY_REPO="${DAISY_REPO:-https://github.com/ivegamsft/daisy-chain.git}"
DAISY_REF="${DAISY_REF:-main}"
TEMP_DIR="$(mktemp -d)"

echo "Syncing dAIsy Chain framework from ${DAISY_REPO}@${DAISY_REF}"

git clone --quiet --depth 1 --branch "${DAISY_REF}" "${DAISY_REPO}" "${TEMP_DIR}"

# Sync framework directories
for dir in docs/factory-process docs/architecture examples factory; do
  if [ -d "${TEMP_DIR}/${dir}" ]; then
    mkdir -p "${dir}"
    rsync -a --delete \
      --exclude "factory-state.json" \
      --exclude "registry.yml" \
      "${TEMP_DIR}/${dir}/" "${dir}/"
    echo "  synced ${dir}/"
  fi
done

# Sync individual files
for file in factory/stamp.ps1 factory/plant.yml factory/README.md; do
  if [ -f "${TEMP_DIR}/${file}" ]; then
    cp "${TEMP_DIR}/${file}" "${file}"
    echo "  synced ${file}"
  fi
done

rm -rf "${TEMP_DIR}"

VERSION=$(cat .daisy-chain-version 2>/dev/null || echo "unknown")
NEW_VERSION=$(date +%Y%m%d)
echo "${NEW_VERSION}" > .daisy-chain-version

echo ""
echo "dAIsy Chain sync complete. Version: ${NEW_VERSION} (was: ${VERSION})"
echo "Review changes with: git diff"
