#!/bin/bash
set -e

# ── SSH ──────────────────────────────────────────────────────────────────────
echo "$SSH_PUBLIC_KEY" > /home/claude/.ssh/authorized_keys
chown -R claude:claude /home/claude/.ssh
chmod 600 /home/claude/.ssh/authorized_keys

# Ensure home permissions survive mounted volumes
chown claude:claude /home/claude
chmod 750 /home/claude

# ── Tailscale ────────────────────────────────────────────────────────────────
tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale &

# Wait for tailscaled socket instead of a fixed sleep
for i in $(seq 1 10); do
    tailscale status >/dev/null 2>&1 && break
    sleep 1
done

tailscale up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --hostname="${TAILSCALE_HOSTNAME:-claude-container}" \
    --accept-routes=false \
    --shields-up=false

# ── sshd ─────────────────────────────────────────────────────────────────────
exec /usr/sbin/sshd -D -e
