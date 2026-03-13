<div align="center">
  <h1>🚀 Claude Containers</h1>
  <p><b>Two isolated development containers, accessible via SSH through Tailscale.</b></p>
</div>

---

## 📂 Structure

```text
claude-containers/
├── base/               # Shared base image (Node 22, Tailscale, Claude Code, sshd)
├── antigravity/        # Container for Antigravity Remote SSH (adds wget)
├── pure/               # Pure CLI container (tmux, ripgrep, vim, jq, fd...)
├── compose.yaml
└── .env
```

---

## 🚀 Getting Started

### 1. Create `.env`

Create a `.env` file in the project root with the following variables:

```bash
# Your SSH public key (paste the full contents of ~/.ssh/id_ed25519.pub)
SSH_PUBLIC_KEY=ssh-ed25519 AAAA...

# Tailscale auth keys — one per container (see step 2)
TAILSCALE_AUTHKEY_ANTIGRAVITY=tskey-auth-...
TAILSCALE_AUTHKEY_PURE=tskey-auth-...

# Claude authentication — choose one option (see "Claude Authentication" section below)
ANTHROPIC_API_KEY=sk-ant-...   # Option A: API key — leave unset if using Claude Max login
```

### 2. Generate Tailscale Auth Keys

Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys) → **Generate auth key**:

- **Reusable**: ✅ Yes (to survive container restarts)
- **Ephemeral**: ✅ Yes (nodes self-delete when the container stops)
- **Tags**: Optional, useful for ACLs (e.g. `tag:dev-containers`)

Generate **two separate keys** and assign them to `TAILSCALE_AUTHKEY_ANTIGRAVITY` and `TAILSCALE_AUTHKEY_PURE`.

### 3. Create the local Docker network

`compose.yaml` references `dokploy-network` as an external network (required for Dokploy). Create it locally once:

```bash
docker network create dokploy-network
```

### 4. Build Images

The base image is published to GHCR via CI. Pull it, then build the child images:

```bash
# Pull the pre-built base image from GHCR
docker pull ghcr.io/lmangueira/claude-containers/claude-base:latest

# Build the child images
docker build -t claude-antigravity:latest ./antigravity
docker build -t claude-pure:latest ./pure
```

Or use Compose directly (it will pull the base from GHCR automatically):

```bash
docker compose build
```

### 5. Start the Containers

```bash
docker compose up -d claude-antigravity claude-pure
```

### 5. View Logs

```bash
docker compose logs -f
```

### 6. Verify Nodes in Tailscale

Check the [Tailscale Machines dashboard](https://login.tailscale.com/admin/machines). You should see:

- 🟢 `claude-antigravity`
- 🟢 `claude-pure`

---

## 🔌 SSH Connection

Add the following to your `~/.ssh/config`:

```ssh-config
# Antigravity Remote SSH
Host claude-antigravity
    HostName claude-antigravity
    User claude
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent no

# Pure CLI (auto-attaches to a persistent tmux session)
Host claude-pure
    HostName claude-pure
    User claude
    IdentityFile ~/.ssh/id_ed25519
    RemoteCommand tmux new-session -A -s main
    RequestTTY yes
```

Then connect:

```bash
ssh claude-antigravity
ssh claude-pure
```

---

## 🔑 Claude Authentication

Two options — pick whichever fits your setup. The auth token/key is stored in `~/.claude/` which is on the persistent volume, so you only authenticate once per container.

### Option A — Anthropic API key

Set `ANTHROPIC_API_KEY` in your `.env` (or Dokploy environment variables). Claude Code picks it up automatically on start.

### Option B — Claude Max subscription (OAuth login)

Skip the API key entirely. After SSHing into a container, run:

```bash
claude login
```

Claude Code prints a URL — open it in your browser, sign in with your claude.ai account, and paste the code back. Done. The session persists in the volume across restarts.

---

## 🌌 Antigravity Connection

1. Open **Antigravity**
2. Press `Cmd+Shift+P` → **Remote-SSH: Connect to Host...**
3. Choose `claude-antigravity`
4. The server installs automatically into `~/.antigravity-server/`

### 📝 Extension Marketplace

By default Antigravity uses the **Open VSX Registry**. To use the official VS Code Marketplace:

1. `Settings` → `Antigravity Settings` → `Editor`
2. Update the marketplace URLs to the official VS Code ones
3. Restart Antigravity

---

## 💾 Persistent Volumes

| Volume | Contents |
|---|---|
| `antigravity_home` | `~/.antigravity-server`, `~/.claude`, bash history |
| `antigravity_workspace` | Project files |
| `pure_home` | `~/.claude`, bash history, tmux config |
| `pure_workspace` | Project files |
| `tailscale_antigravity` | Tailscale state (avoids re-auth on every restart) |
| `tailscale_pure` | Tailscale state |

---

## 🔄 Rebuild After Changes

```bash
# Rebuild a single container (e.g. after editing its Dockerfile)
docker compose build --no-cache claude-antigravity
docker compose up -d claude-antigravity

# Rebuild everything from scratch
docker build --no-cache -t claude-base:latest ./base
docker compose build --no-cache claude-antigravity claude-pure
docker compose up -d claude-antigravity claude-pure
```

---

## ☁️ Deploying to Dokploy

See **[DEPLOY_DOKPLOY.md](DEPLOY_DOKPLOY.md)** for a step-by-step guide to deploying this project on a Dokploy instance, including how to handle the base image build order, required `compose.yaml` changes, environment variable setup, and persistent volume management.

---

## 🛑 Stop & Remove

```bash
# Stop containers (volumes are preserved)
docker compose down

# Stop and delete all volumes (destructive — loses all data)
docker compose down -v
```
