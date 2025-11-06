#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Running pre-commit hook: decrypting secrets..."

SECRETS_DIR="files/secrets"

if [[ -z "${SOPS_AGE_KEY_FILE:-}" ]]; then
  echo "❌ SOPS_AGE_KEY_FILE not set. Please export it before committing."
  exit 1
fi

for file in $(find "$SECRETS_DIR" -type f -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env"); do
  if grep -q '"sops":' "$file"; then
    echo "→ Decrypting: $file"
    sops --decrypt "$file" > "${file%.json}.decrypted.json"
  else
    echo "→ Skipping non-encrypted file: $file"
  fi
done

echo "✅ Secrets decrypted locally (not committed)."
