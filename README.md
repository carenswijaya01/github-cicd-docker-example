# GitHub Actions CI/CD with GHCR & Staging Deploy

This repository demonstrates a **CI/CD pipeline** using:

- **GitHub Actions** for automation
- **GitHub Container Registry (GHCR)** for storing Docker images
- **Docker Compose** for deployment to a remote staging server via SSH
- **Multi-architecture builds** for both AMD64 and ARM64

---

## 📦 Workflow Summary

1. **Trigger** → Push to the `staging` branch
2. **Build & Push** → Docker multi-arch image to GHCR (`latest` + version tag)
3. **Deploy** → SSH into staging server, run `docker compose pull` and `docker compose up -d`

---

## 🔑 Required Variables & Secrets

### Variables (Repository → Settings → Actions → Variables)

| Name    | Example Value | Description     |
| ------- | ------------- | --------------- |
| VERSION | 1.0.0         | App version tag |

### Secrets (Repository → Settings → Actions → Secrets)

| Name            | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| GHCR_PAT        | GitHub Personal Access Token with `write:packages` & `read:packages` |
| STAGING_HOST    | Staging server hostname/IP                                           |
| STAGING_USER    | SSH user for staging server                                          |
| STAGING_PATH    | Path to project on staging server                                    |
| SSH_PRIVATE_KEY | Private key for SSH authentication                                   |

---

## 🚀 Usage

### Build & Push Multi-Arch Image (Manually)

```bash
docker buildx build --platform linux/amd64,linux/arm64/v8 \
  -t ghcr.io/<username>/<repo>:$VERSION \
  -t ghcr.io/<username>/<repo>:latest \
  --push .
```

### Deploy to Staging (Manually)

```bash
ssh -i ~/.ssh/id_rsa $STAGING_USER@$STAGING_HOST \
  "cd $STAGING_PATH && docker compose pull && docker compose up -d"
```

---

## 🛠 Troubleshooting

### **1. GHCR Unauthorized Error**

Error:

```
Error Head "https://ghcr.io/v2/<username>/<repo>/manifests/latest": unauthorized
```

**Cause:** You’re not logged in to GHCR or the image is private.

**Fix:**

- Add Docker login in your deploy script:
  ```bash
  echo "$GHCR_PAT" | docker login ghcr.io -u <username> --password-stdin
  ```
- Or make your container public:
  - Go to **GitHub → Packages → Your Image → Package Settings**
  - Change **Package visibility** to `Public`

---

### **2. SSH Handshake Failed**

Error:

```
ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
```

**Cause:** Your server does not recognize your public key.

**Fix:**

- Add your server SSH public key to the server's `~/.ssh/authorized_keys`:
  ```bash
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  ```

---

### **3. Platform Mismatch**

Error:

```
The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8)
```

**Cause:** Image built for AMD64, staging server is ARM64.

**Fix:** Use `docker buildx` for multi-arch builds:

```bash
docker buildx build --platform linux/amd64,linux/arm64/v8 ...
```

Add `docker/setup-qemu-action` and `docker/setup-buildx-action` in your GitHub Actions workflow.

If you only want to build for the `linux/amd64` architecture (the default), replace the script below **Set Version** in your YAML file with the following:

```bash
- name: Build Docker Image
  run: docker build -t ghcr.io/${{ github.actor }}/<repo>:$VERSION .

- name: Push Docker Image
  run: docker push ghcr.io/${{ github.actor }}/<repo>:$VERSION

- name: Tag Image as Latest and Push
  run: |
    docker image tag ghcr.io/${{ github.actor }}/<repo>:$VERSION ghcr.io/${{ github.actor }}/<repo>:latest
    docker push ghcr.io/${{ github.actor }}/<repo>:latest
```
