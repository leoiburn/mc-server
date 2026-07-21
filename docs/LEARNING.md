# 🎓 Crash course: Terminal → Docker → running this server

A fast, practical path to understanding every command in this repo. Do these on
the machine that will host the server.

## Part 1 — Terminal survival kit

| Command | What it does |
|---|---|
| `pwd` | print working directory (where am I?) |
| `ls -lh` | list files, human-readable sizes |
| `cd mc-server` / `cd ..` | change directory / go up one |
| `nano file` | edit a text file (Ctrl-O save, Ctrl-X exit) |
| `cat file` / `less file` | print / scroll a file |
| `cp a b` / `mv a b` / `rm a` | copy / move / **delete** (rm has no undo) |
| `sudo <cmd>` | run as admin (careful) |
| `man <cmd>` or `<cmd> --help` | read the manual |
| `history` | commands you've run |

Handy plumbing:
- `command | grep word` — filter output for `word` (a "pipe").
- `command > file` — save output to a file; `>>` appends.
- `Ctrl-C` stops the current command; `Ctrl-L` clears the screen.

> **Mental model:** the shell reads a line, runs one program, shows its output,
> repeats. Everything below is just running programs with arguments.

## Part 2 — Docker in 6 ideas

1. **Image** = a frozen, ready-to-run app + its dependencies (here: the MC server).
2. **Container** = a running copy of an image, isolated from your OS.
3. **Volume / bind-mount** = a folder shared between container and host so data
   *survives* restarts. Ours is `./data` → the world lives on your real disk.
4. **Port publish** `-p 25565:25565` = forward a host port to the container so
   the outside world can reach the service.
5. **Compose** (`docker-compose.yml`) = declare containers, volumes, ports, and
   settings as a **file** instead of long commands. Reproducible + version-controlled.
6. **Env vars** = the knobs (`MEMORY`, `TYPE`, …). We keep secrets in `.env`.

Core Docker commands:
```bash
docker ps                    # running containers
docker compose up -d         # create/start everything from the yml (detached)
docker compose down          # stop & remove containers (data volume stays)
docker compose logs -f mc    # follow one service's logs
docker exec -it mc bash      # open a shell INSIDE the container
docker stats                 # live CPU/RAM per container
docker system df             # disk used by images/volumes
```

> **Why Compose matters here:** your whole server is described in one file you
> can commit to GitHub and re-run anywhere. That file *is* the deliverable.

## Part 3 — Trace this repo end to end
1. `docker compose up -d` reads `docker-compose.yml`.
2. It pulls `itzg/minecraft-server`, injects your `.env` values as env vars.
3. The image sees `TYPE=FABRIC` + your mod list → downloads Fabric + mods.
4. It writes the world to `/data`, which is bind-mounted to `./data` on disk.
5. `EULA=TRUE` + generated config → server starts, listens on 25565.
6. The `backup` container waits until `mc` is healthy, then tars `/data`
   into `./backups` on a timer, talking to the server via RCON to pause saves.

Read the yml alongside this list — every line will click.

## Part 4 — Put it on GitHub (own your work)
```bash
cd mc-server
git init
git add .                       # .gitignore keeps .env, data/, backups/ out
git status                      # CONFIRM .env is NOT listed
git commit -m "Modded Minecraft server: compose + backups + hardening"

# create an empty repo on github.com first (no README), then:
git branch -M main
git remote add origin https://github.com/<your-username>/mc-server.git
git push -u origin main
```
Future changes: `git add -A && git commit -m "..." && git push`.

> **Golden rule:** before your first push, run `git status` and make sure
> **`.env` is not there**. Secrets in public repos get stolen within minutes.

## Part 5 — Where to go next (cybersecurity)
- `SECURITY.md` in this repo — apply each item, watch the logs react.
- Learn `nmap` by scanning *your own* server: `nmap -sV <server-ip>`.
- Try `fail2ban-client status sshd` after a day — see real attempts get banned.
- Keep a "runbook": every time you fix something, write down what you did.
  That habit is 80% of being good at ops/security.
