#!/usr/bin/env bash
set -euo pipefail

echo "🔒 Encrypting SOPS secrets, values, and environment files before commit/push..."

# Helper: check if a file is already encrypted
is_sops_encrypted() {
  grep -q '^sops:' "$1" || grep -q '"sops":' "$1"
}

# Helper: detect sensitive keys for values.yaml (only ENCRYPTED_ prefix)
detect_encrypted_prefix_keys() {
  local file="$1"
  echo "   🔍 Scanning $file for ENCRYPTED_ keys..."
  grep -E "^[[:space:]]*.*ENCRYPTED_.*:" "$file" \
    | sed 's/^[[:space:]]*//g' \
    | sed 's/:.*//g' \
    | sort -u \
    | awk '{print "     • " $1}'
}

# Helper: detect sensitive keys for .env files
detect_sensitive_keys() {
  local file="$1"
  echo "   🔍 Scanning $file for sensitive keys..."
  grep -E "^[[:space:]]*.*(password|token|secret|key|credential|auth).*:" "$file" \
    | sed 's/^[[:space:]]*//g' \
    | sed 's/:.*//g' \
    | sort -u \
    | awk '{print "     • " $1}'
}

# =======================================
# 1️⃣ Encrypt files under files/secrets/ (FULL FILE)
# =======================================
SECRET_DIR="files/secrets"
if [ -d "$SECRET_DIR" ]; then
  for file in "$SECRET_DIR"/*.{json,yaml,yml,env}; do
    [[ -f "$file" ]] || continue
    if is_sops_encrypted "$file"; then
      echo "⚪ Already encrypted: $file"
    else
      echo "   📄 Full file encryption (all content will be encrypted)"
      echo "🔐 Encrypting secret file in place: $file"
      sops --encrypt --in-place "$file"
      echo "✅ Encrypted: $file"
    fi
  done
else
  echo "⚠️ No secrets directory found at $SECRET_DIR"
fi

# =======================================
# 2️⃣ Encrypt Helm values files (only ENCRYPTED_ prefix)
# =======================================
for file in values*.yaml; do
  [[ -f "$file" ]] || continue
  if is_sops_encrypted "$file"; then
    echo "⚪ Already encrypted: $file"
  else
    detect_encrypted_prefix_keys "$file" || true
    echo "🔐 Encrypting Helm values file in place (ENCRYPTED_ keys only): $file"
    sops --encrypt --in-place "$file"
    echo "✅ Encrypted: $file"
  fi
done

# =======================================
# 3️⃣ Encrypt root-level .env files (sensitive keys)
# =======================================
for file in .env .env.*; do
  [[ -f "$file" ]] || continue
  if is_sops_encrypted "$file"; then
    echo "⚪ Already encrypted: $file"
  else
    detect_sensitive_keys "$file" || true
    echo "🔐 Encrypting environment file in place: $file"
    sops --encrypt --in-place "$file"
    echo "✅ Encrypted: $file"
  fi
done

# =======================================
# 4️⃣ Auto-stage encrypted files for Git
# =======================================
#git add files/secrets/* values*.yaml .env .env.* 2>/dev/null || true

#echo ""
echo "✅ All encryption completed successfully."
echo "   📁 files/secrets/*: Full file encryption"
echo "   📋 values*.yaml: Only ENCRYPTED_ prefixed keys"
echo "   🔑 .env files: All sensitive keys (password, token, secret, key, credential, auth)"