# 🔐 Securing the server (and learning cybersecurity by doing)

You're exposing a service to a network. That's a great, low-stakes way to learn
real defensive security. Work top-to-bottom; each item says **why** it matters.

## 1. Reduce the attack surface — only open what you need
The container publishes **only** `25565`. Don't expose RCON (25575) or the Docker
API to the network. Verify what's actually listening:

```bash
sudo ss -tulpn        # every listening port + the process behind it
```
> **Why:** every open port is a door. Fewer doors, fewer locks to pick.

## 2. Host firewall (UFW) — default-deny
```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp        # SSH (see #4 — consider limiting the source)
sudo ufw allow 25565/tcp     # Minecraft
sudo ufw enable
sudo ufw status verbose
```
> **Why:** even if some service starts listening by mistake, the firewall
> won't let strangers reach it.

## 3. Keep the system & image patched
```bash
sudo apt update && sudo apt full-upgrade -y     # OS packages
docker compose pull && docker compose up -d      # newer server image
```
> **Why:** most real-world break-ins use *known* bugs that a patch already fixed.

## 4. Harden SSH (how you administer the box)
Prefer keys over passwords. On your laptop:
```bash
ssh-keygen -t ed25519            # once, if you don't have a key
ssh-copy-id user@server          # install your public key on the server
```
Then on the server edit `/etc/ssh/sshd_config`:
```
PasswordAuthentication no
PermitRootLogin no
```
`sudo systemctl restart ssh`.
> **Why:** passwords get brute-forced; a 256-bit key does not. This is the single
> biggest win for a box you log into.

## 5. Block brute-force with fail2ban
```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd    # watch it ban attackers
```
> **Why:** turns thousands of guess attempts into a few, then a ban.

## 6. Secrets hygiene
- Secrets live in `.env`, which is **git-ignored** — confirm before every push:
  `git status` should never list `.env`.
- If you *ever* commit a secret, rotate it (change the password) — deleting the
  file later doesn't erase it from git history.
- Lock the file down: `chmod 600 .env`.
> **Why:** leaked credentials in public repos are scraped by bots within minutes.

## 7. Least privilege for the game itself
- `online-mode=false` (needed for the password gate) means the *server* doesn't
  verify Mojang accounts — so the **EasyAuth password IS your security**. Encourage
  strong per-player passwords, and keep `OPS` limited to people you trust.
- Only give `op` (admin) to accounts that need it. Admins can run anything.
> **Why:** the fewer people with god-mode, the smaller the blast radius of a mistake.

## 8. Backups ARE security (ransomware/corruption/fat-fingers)
Automatic backups run already. Add an **offsite** copy so one dead disk or bad
actor can't erase everything:
```bash
rsync -a backups/ user@another-host:mc-backups/    # or a cron job / restic to cloud
```
Test a restore once (`./scripts/restore.sh`) so you *know* it works.
> **Why:** the goal isn't "never get hit," it's "recover fast when you do."

## 9. Know what "normal" looks like
```bash
docker compose logs -f mc          # watch join/leave + errors
sudo journalctl -u ssh -f          # watch SSH auth attempts
```
> **Why:** you can only spot an intrusion if you know your baseline.

---
### A responsible-hacker note
These techniques are for **your own systems** (or ones you're explicitly
authorized to test). Same skills, very different legality depending on consent.
Learn them here, apply them only where you have permission.

## Firewall & IP rate limiting
`scripts/firewall.sh` sets up the host firewall:
- **ufw**: deny all inbound, allow Minecraft, rate-limit SSH.
- **Per-IP limits on Minecraft** (in Docker's `DOCKER-USER` chain, because Docker-published ports skip ufw):
  max 3 simultaneous connections per IP and 10 new connections per minute per IP (burst 20). Stops connection floods and bot join spam.
- Tune with env vars: `MC_PORT`, `MAX_CONN_PER_IP`, `NEW_PER_MIN`.

## Port forwarding
Only TCP 25565 is forwarded from the router to this host. RCON, SSH and Docker are never forwarded.
