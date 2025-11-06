#!/usr/bin/env bash
set -euo pipefail

echo "🔒 Encrypting SOPS secrets and values files before push..."

# Helper function: check if file already encrypted (contains SOPS metadata)
is_sops_encrypted() {
  grep -q '^sops:' "$1" || grep -q '"sops":' "$1"
}

# =======================================
# 1️⃣ Encrypt files under files/secrets/
# =======================================
SECRET_DIR="files/secrets"
if [ -d "$SECRET_DIR" ]; then
  for file in "$SECRET_DIR"/*.{json,yaml,yml,env}; do
    [[ -f "$file" ]] || continue
    if is_sops_encrypted "$file"; then
      echo "⚪ Already encrypted: $file"
    else
      echo "🔐 Encrypting secret file in place: $file"
      sops --encrypt --in-place "$file"
    fi
  done
else
  echo "⚠️ No secrets directory found at $SECRET_DIR"
fi

echo "✅ All plaintext files have been encrypted successfully."
