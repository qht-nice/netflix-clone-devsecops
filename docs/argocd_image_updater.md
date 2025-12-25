# Argo CD Image Updater (This Repo)

This document describes how **Argo CD Image Updater** is set up in this repository to automatically deploy new Docker images by **writing back** updated image tags to Git.

## What it does

- Jenkins builds and pushes new images to DockerHub:
  - `qhtsg/netflix-frontend:<tag>`
  - `qhtsg/netflix-backend:<tag>`
- Argo CD Image Updater detects newer tags and updates `Kubernetes/base/kustomization.yaml`
- Argo CD sees the Git change and syncs the cluster automatically.

## Where it is configured

- **Argo CD Application**: `Kubernetes/argocd-application.yml`
- **Kustomize tags file (write-back target)**: `Kubernetes/base/kustomization.yaml`
- **Deployments (image names)**: `Kubernetes/base/deployment.yml`

## Current configuration (important bits)

### Argo CD Application annotations

File: `Kubernetes/argocd-application.yml`

- **Enable updater**: `argocd-image-updater.argoproj.io/enabled: "true"`
- **Images tracked**:
  - `argocd-image-updater.argoproj.io/image-list: backend=qhtsg/netflix-backend,frontend=qhtsg/netflix-frontend`
- **Allowed tags**:
  - `argocd-image-updater.argoproj.io/* .allow-tags: regexp:^[0-9]+$`
  - Only numeric tags are deployed (recommended for CI build numbers).
- **Write-back mode (Kustomize)**:
  - `argocd-image-updater.argoproj.io/write-back-target: kustomization`
  - `argocd-image-updater.argoproj.io/kustomize.path: Kubernetes/base`
- **Git write-back credentials**:
  - `argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/argocd-image-updater-git-creds`
- **Branch to write back to**:
  - `argocd-image-updater.argoproj.io/git-branch: dev`
- **Argo CD source branch**:
  - `.spec.source.targetRevision: dev`

### Kustomize image tags

File: `Kubernetes/base/kustomization.yaml`

Image Updater updates the `newTag` fields:

```yaml
images:
  - name: qhtsg/netflix-backend
    newTag: "23"
  - name: qhtsg/netflix-frontend
    newTag: "23"
```

## Required Kubernetes secrets

### 1) DockerHub pull secret (for private images / rate limits)

Referenced by the Application annotation:

- `argocd-image-updater.argoproj.io/pull-secret: pullsecret:argocd/argocd-image-updater-secret`

Verify:

```bash
kubectl get secret -n argocd argocd-image-updater-secret
```

### 2) Git write-back credentials (required)

Secret name used by this repo:

- `argocd-image-updater-git-creds` (namespace: `argocd`)

It must include:
- `username`: your GitHub username
- `password`: a GitHub PAT with repo write permissions

Create:

```bash
kubectl -n argocd create secret generic argocd-image-updater-git-creds \
  --from-literal=username='<YOUR_GITHUB_USERNAME>' \
  --from-literal=password='<YOUR_GITHUB_PAT>'
```

## Installing / verifying Image Updater

### Verify it is running

```bash
kubectl get deploy -n argocd argocd-image-updater
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-image-updater
```

### Verify config (in-cluster)

The Image Updater reads from:

- ConfigMap: `argocd-image-updater-config` (namespace: `argocd`)

Common keys used in this cluster:
- `argocd.server_addr: argocd-server.argocd:443`
- `argocd.insecure: true`

Check:

```bash
kubectl get configmap -n argocd argocd-image-updater-config -o yaml
```

### Check logs

```bash
kubectl logs -n argocd deploy/argocd-image-updater --tail=200
```

Look for lines like:
- `Setting new image to ...`
- `git commit ...`
- `git push origin <branch>`

## Troubleshooting

### Image Updater says “credentials not configured”

Symptoms:
- `credentials for '<repo-url>' are not configured...`

Fix:
- Ensure `write-back-method` points to a secret that has `username` and `password`.
- Ensure PAT has write access to the repo and branch.

### Image Updater says “does not contain field username”

Cause:
- You referenced a Docker pull secret (`.dockerconfigjson`) as git creds.

Fix:
- Use a separate secret for git write-back (see `argocd-image-updater-git-creds`).

### Argo CD stays on old revision

Force refresh:

```bash
kubectl patch application -n argocd netflix-app --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Tags “go backwards” or keep becoming `1`

Cause:
- PR builds or multibranch jobs reset `BUILD_NUMBER` per branch/PR.

Fix:
- Keep `allow-tags: ^[0-9]+$`
- Ensure CI generates tags that are numeric and monotonically increasing for the branch Argo CD tracks.


