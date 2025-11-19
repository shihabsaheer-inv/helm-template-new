# 🚀 Helm Template Standard

A secure, reusable **Helm chart** for deploying containerized applications across multiple environments (`dev`, `staging`, `prod`) with built-in **SOPS-based secret encryption**, **pre-commit automation**, and **environment-specific overrides**.

---

## 📁 Project Structure
```
.
├── Chart.yaml                      # Helm chart metadata
├── values.yaml                     # Base default values
├── values-override/
│   ├── values-dev.yaml             # Dev environment overrides
│   ├── values-staging.yaml         # Staging environment overrides
│   └── values-prod.yaml            # Production overrides
├── files/
│   ├── config/                     # ConfigMap source files
│   │   ├── application.properties
│   │   ├── dev1.yaml
│   │   └── dev.json
│   └── secrets/                    # Secrets (fully encrypted)
│       ├── secrets.json
│       └── secrets1.json
├── templates/                      # Helm templates for Kubernetes resources
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── ingress.yaml
│   ├── rollout.yaml
│   ├── hpa.yaml
│   └── istio.yaml
├── scripts/
│   └── encrypt-secrets.sh          # SOPS encryption automation
├── .sops.yaml                      # Encryption rules
├── .pre-commit-config.yaml         # Pre-commit hook configuration
└── CHANGELOG.md                    # Project changelog
```

---

## 🧩 Features

✅ **Multi-environment support**
- `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml` for clean environment isolation.

🔐 **SOPS-based secret encryption**
- Automatically encrypts any environment variable starting with `ENCRYPTED_`.
- Fully encrypts secret files under `files/secrets/`.

🧠 **Pre-commit hook automation**
- Automatically runs `scripts/encrypt-secrets.sh` before every `git commit` to ensure secrets are always encrypted.

🧰 **Helm best practices**
- Configurable `resources`, `probes`, and `rollout` parameters.
- Clean modular templates for Deployment, Service, ConfigMap, etc.
- NodePort for local dev environments.

---

## ⚙️ Prerequisites

| Tool | Minimum Version | Purpose |
|------|------------------|----------|
| [Helm](https://helm.sh/docs/intro/install/) | v3.8+ | Chart management |
| [SOPS](https://github.com/mozilla/sops) | v3.8+ | Secret encryption/decryption |
| [age](https://github.com/FiloSottile/age) | v1.0+ | Encryption key management |
| [yq](https://github.com/mikefarah/yq) | v4.0+ | YAML processing |
| [jq](https://stedolan.github.io/jq/) | v1.6+ | JSON processing |
| [pre-commit](https://pre-commit.com) | v3.0+ | Git hook automation |

---

## 🗝️ Setup SOPS Encryption

### 1️⃣ Generate an AGE key pair
```bash
age-keygen -o ~/.config/sops/age/keys.txt
```

Output example:
```
# created: 2025-11-07T07:00:00Z
# public key: age1t4pcys2s6n3m2xt0lgn0e2yetcdwazyxfd0mztrza8qssye4vqeswusptz
AGE-SECRET-KEY-1....
```

### 2️⃣ Export the key for SOPS
```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

Your `.sops.yaml` already references the same AGE recipient key.

---

## 🔐 Secrets & Encryption Rules

### 📄 `.sops.yaml`
```yaml
# Fully encrypt all files under files/secrets/
- path_regex: files/secrets/.*\.(yaml|yml|json|env)$
  encrypted_regex: '.*'
  encryption_method: aes256_gcm

# Encrypt only ENCRYPTED_* vars in values files
- path_regex: (values(-.*)?\.ya?ml)$
  encrypted_regex: '(?i)^.*ENCRYPTED_.*$'
  encryption_method: aes256_gcm
```

✅ Example (`values-dev.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: dev
  - name: ENCRYPTED_API_KEY
    value: "my-secret-api-key"
```

After encryption:
```yaml
env:
  - name: ENVIRONMENT
    value: dev
  - name: ENCRYPTED_API_KEY
    value: "ENC[AES256_GCM,data:mGSV7As72Mrojkksna65aw==,...]"
```

---

## 💥 Pre-commit Hook Setup

### 1️⃣ Install pre-commit
```bash
pip install pre-commit
```

### 2️⃣ Install hooks
```bash
pre-commit install --overwrite
chmod +x scripts/encrypt-secrets.sh
```

### 3️⃣ Verify
```bash
pre-commit run --all-files
```

✅ Output:
```
Encrypt SOPS secrets before push.....................................Passed
```

### 4️⃣ On every commit
When you `git commit`, it:
- Scans all Helm `values*.yaml` for `ENCRYPTED_` keys.
- Encrypts them automatically.
- Re-adds the updated files to the commit.

---

## 🚀 Deploying the Helm Chart

### 🧱 Development
```bash
helm upgrade --install my-app ./  --values values-override/values-dev.yaml
```

### 🧪 Staging
```bash
helm upgrade --install my-app ./  --values values-override/values-staging.yaml
```

### 🏭 Production
```bash
helm upgrade --install my-app ./  --values values-override/values-prod.yaml
```

### 🧩 Preview manifests
```bash
helm template my-app ./  --values values-override/values-dev.yaml
```

---

## 🧹 Cleanup
```bash
helm uninstall my-app
```

To decrypt files (for local testing only):
```bash
sops --decrypt --in-place values-override/values-dev.yaml
sops --decrypt --in-place files/secrets/secrets.json
```

---

## 🧪 Testing Encryption Flow
1. Add new secret:
   ```yaml
   - name: ENCRYPTED_API_KEY
     value: my-new-key
   ```
2. Run:
   ```bash
   ./scripts/encrypt-secrets.sh
   ```
3. Confirm encryption:
   ```bash
   grep ENCRYPTED_API_KEY values-override/values-dev.yaml
   ```
4. Decrypt for testing:
   ```bash
   sops --decrypt values-override/values-dev.yaml
   ```

---

## 🧱 CI/CD Integration (Optional)
Add this file: `.github/workflows/helm-lint-sops-validate.yml`
```yaml
name: Helm Lint & SOPS Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Helm
        uses: azure/setup-helm@v4
        with:
          version: v3.13.0

      - name: Install SOPS
        run: sudo apt-get install -y sops

      - name: Validate Helm Chart
        run: helm lint .

      - name: Validate SOPS Files
        run: |
          for file in $(grep -rl '^sops:' .); do
            echo "🔍 Checking $file"
            sops --decrypt "$file" >/dev/null
          done
```

### 🔐 SOPS Key
Please access the link view the key: https://drive.google.com/file/d/1LQOZRx0jc0AGzPCRJXiAVRnP7h4KxTMO/view?usp=sharing

## 🧠 Troubleshooting

| Error | Cause | Fix |
|-------|--------|-----|
| `MAC mismatch` | File edited after encryption | Remove `sops:` block and re-encrypt |
| `no matching creation rules found` | `.sops.yaml` regex mismatch | Fix path regex |
| `command not found: yq` | Dependency missing | `sudo apt install yq` |

---

## 🤝 Contributing
1. Fork this repo  
2. Create a new branch (`feature/my-feature`)  
3. Commit and push your changes  
4. Open a Pull Request 🎉

---
