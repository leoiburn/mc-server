# 🟩 Modded Minecraft Server (Java) — portable & self-hosted

A one-command, mod-loaded Minecraft server you can run on **any Linux machine**
with Docker. Comes with **automatic backups**, a **password login gate**, and
**security hardening**. Built to be cloned, understood, and re-run by *you*.

- **Stack:** Docker + [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server) (the community standard)
- **Loader:** Fabric (light & fast) — swap to Forge/NeoForge in `docker-compose.yml`
- **Mods:** a Modrinth modpack URL *or* a hand-picked mod list
- **Access:** anyone can join, each player sets a password (EasyAuth mod)
- **Backups:** automatic every 2h, auto-pruned after 7 days

> New to the terminal, Docker, or security? Read [`docs/LEARNING.md`](docs/LEARNING.md)
> and [`SECURITY.md`](SECURITY.md) — they explain the *why* behind every step.

---

## 1. What you need on the server machine

Docker Engine + the Compose plugin. On Debian/Ubuntu/Kali:

```bash
# install Docker (official convenience script)
curl -fsSL https://get.docker.com | sudo sh
# let your user run docker without sudo (log out/in after this)
sudo usermod -aG docker "$USER"
# verify
docker --version && docker compose version
```

## 2. Get the project onto the machine

```bash
git clone https://github.com/<your-username>/mc-server.git
cd mc-server
```

## 3. Configure your secrets & settings

```bash
cp .env.example .env
# generate a strong RCON password and see it:
openssl rand -base64 24
nano .env          # paste the password into RCON_PASSWORD, set OPS_USERS, RAM, etc.
```

Everything you'd tweak lives in `.env` (secrets/sizing) and `docker-compose.yml`
(structure). The real `.env` is git-ignored, so **your secrets never reach GitHub**.

## 4. Start it

```bash
docker compose up -d          # start in the background
docker compose logs -f mc     # watch it boot & download mods (Ctrl-C to stop watching)
```

First boot downloads the mods and generates the world — give it a few minutes.
When you see `Done (…)! For help, type "help"` it's live on port **25565**.

## 5. Join & set your password

In Minecraft (Java Edition), **Multiplayer → Add Server →** the machine's IP.
On first join the EasyAuth mod makes you register:

```
/register <yourpassword> <yourpassword>
```

Next time you connect: `/login <yourpassword>`. That's your "open to everyone,
but password-protected" setup.

> **Make yourself admin:** put your Minecraft username in `OPS_USERS` in `.env`
> (then `docker compose up -d` again), or run `op <name>` in the server console.

---

## Everyday commands (your cheat sheet)

```bash
docker compose ps                 # is it running?
docker compose logs -f mc         # live logs
docker attach mc                  # open the SERVER CONSOLE (type commands like `op`, `say`)
#   ^ detach WITHOUT stopping the server:  Ctrl-p  then  Ctrl-q
docker compose restart mc         # restart
docker compose down               # stop & remove containers (world is safe in ./data)
docker compose pull && docker compose up -d   # update to newer image
```

Run a single console command over RCON without attaching:

```bash
docker exec mc rcon-cli list      # who's online
docker exec mc rcon-cli say hi    # broadcast a message
```

---

## Backups

The `backup` container snapshots the world automatically (interval & retention
set in `.env`). Snapshots land in `./backups/` as `.tgz` files.

- **List them:** `ls -lh backups/`
- **Restore one:** `./scripts/restore.sh` (newest) or `./scripts/restore.sh backups/<file>.tgz`
- **Offsite copy (recommended):** periodically `rsync backups/ user@another-host:mc-backups/`
  so a dead disk can't take your world with it. See `SECURITY.md`.

> A backup you've never restored is a rumor, not a backup. Do a test restore once.

---

## Making it "many mods"

**Option A — a ready-made pack (easiest):** browse
[modrinth.com/modpacks](https://modrinth.com/modpacks), pick a **server-friendly**
pack, copy its `.mrpack` download URL into `MODPACK_URL` in `.env`, then
`docker compose up -d`. Match `MC_VERSION` to the pack.

**Option B — hand-pick:** edit the `MODRINTH_PROJECTS` list in `docker-compose.yml`.
Use the slug from each mod's Modrinth URL (e.g. `modrinth.com/mod/lithium` → `lithium`).
itzg auto-downloads their required dependencies.

⚠️ Every mod must support your `MC_VERSION` **and** Fabric, and be **server-side**
capable. Client-only mods won't load server-side (that's normal).

---

## Run it on a different machine later

Because the world/secrets are *not* in git, moving hosts is clean:

```bash
# on the OLD machine — grab a fresh backup, then copy the repo + newest snapshot
# on the NEW machine:
git clone https://github.com/<you>/mc-server.git && cd mc-server
cp .env.example .env && nano .env          # re-enter secrets
mkdir -p data && tar -xzf /path/to/latest-backup.tgz -C data   # bring the world along
docker compose up -d
```

Same repo, any Linux box. That's the point.

---

## Project layout

```
mc-server/
├── docker-compose.yml   # the whole server, declared as code
├── .env.example         # template for your settings/secrets (copy to .env)
├── .gitignore           # keeps secrets & world data out of git
├── scripts/restore.sh   # one-command world restore
├── docs/LEARNING.md     # terminal + Docker + security crash course
├── SECURITY.md          # how to lock the box down (and why)
└── data/  backups/      # created at runtime, never committed
```
