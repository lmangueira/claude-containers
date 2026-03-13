# Deploying to Dokploy

> **Important:** Use **Docker Compose** mode, not Docker Stack (Swarm). Swarm silently drops `cap_add`, `build:`, and `restart: unless-stopped` — all of which this project requires.

---

## Prerequisites

- A Dokploy instance (self-hosted or cloud) with a server attached
- The repo pushed to GitHub (or any Git provider)
- Tailscale auth keys (see [README.md](README.md#2-generate-tailscale-auth-keys))

---

## 1. First-time base image push

The base image is built automatically by CI (`.github/workflows/build-base.yml`) on every push that touches `./base/`. Before the **first deploy**, push it manually so Dokploy can pull it:

```bash
docker build -t ghcr.io/lmangueira/claude-containers/claude-base:latest ./base
docker push ghcr.io/lmangueira/claude-containers/claude-base:latest
```

After that, any change to `./base/` pushed to `main`/`master` will rebuild and push the base image automatically. Dokploy picks it up on the next deploy.

---

## 2. Create the Compose Service in Dokploy

1. In the Dokploy dashboard, click **Create Project** (e.g. `claude-containers`)
2. Inside the project, click **Create Service** → **Compose**
3. Set **Compose Type** to **Docker Compose** (not Stack)
4. Under **Provider**, connect your GitHub account and select the repo and branch
5. Set **Compose File Path** to `compose.yaml`
6. Click **Save**

---

## 3. Set Environment Variables

Go to the service's **Environment** tab and add:

```
ANTHROPIC_API_KEY=sk-ant-...
SSH_PUBLIC_KEY=ssh-ed25519 AAAA...
TAILSCALE_AUTHKEY_ANTIGRAVITY=tskey-auth-...
TAILSCALE_AUTHKEY_PURE=tskey-auth-...
```

> **Note on `SSH_PUBLIC_KEY`:** The value contains spaces. Wrap it in double quotes in the Dokploy UI, or the `.env` parser may truncate it at the first space.

> **Note:** Environment variable changes in Dokploy do **not** trigger an automatic redeploy. After saving new values, manually click **Deploy**.

---

## 4. Deploy

Click **Deploy** in the Dokploy dashboard. Dokploy will:

1. Clone the repo
2. Write the env vars to a `.env` file
3. Run `docker compose up -d --build`

Monitor progress in the **Logs** tab.

### Enable Auto-Deploy on Push (optional)

1. Go to the service → **General** tab → enable **Auto Deploy**
2. Dokploy shows a webhook URL — add it to your GitHub repo under **Settings → Webhooks** (trigger: push events)

---

## 5. Verify

1. Check **Dokploy Logs** — both containers should start without errors
2. Check the [Tailscale Machines dashboard](https://login.tailscale.com/admin/machines) — you should see `claude-antigravity` and `claude-pure` come online
3. SSH in from your machine:

```bash
ssh claude-antigravity
ssh claude-pure
```

---

## Persistent Volumes

Named volumes are managed by Docker on the server and survive redeployments. Dokploy's **Volume Backups** feature (S3 export) can back them up automatically — configure it in server settings.

> **Warning:** The `tailscale_antigravity` and `tailscale_pure` volumes store each node's Tailscale identity. **Never delete them between deploys** or the containers will re-register as new nodes and require fresh auth keys.

> **Warning:** `docker compose down -v` and Dokploy's "Remove Volumes" option will destroy all data. Avoid unless intentional.

---

## Rebuilding After Base Image Changes

Push to `main`/`master` with changes under `./base/` — the CI workflow rebuilds and pushes `claude-base:latest` automatically. Then trigger a Dokploy deploy (manually or via webhook) so the child images are rebuilt against the new base.

For changes to `./antigravity/` or `./pure/` only, a regular deploy is sufficient — no base rebuild needed.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Child build fails with `pull access denied for claude-base` | Base image not yet pushed to GHCR | Run the manual push in step 1 |
| Tailscale never connects | `TAILSCALE_AUTHKEY_*` is wrong or expired | Generate new auth keys and redeploy |
| Logs missing / metrics broken | `container_name:` added back to compose.yaml | Remove `container_name:` from both services |
| Container starts but Tailscale fails silently | Using Stack mode instead of Compose mode | Verify Compose Type is "Docker Compose" not "Stack" |
| `SSH_PUBLIC_KEY` is empty inside container | Spaces in value truncated by dotenv parser | Wrap value in double quotes in Dokploy env UI |
