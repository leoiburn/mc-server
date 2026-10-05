#!/usr/bin/env bash
# Simple firewall for the Minecraft host. Run as root: sudo ./scripts/firewall.sh
# - Host: deny all inbound except SSH (rate-limited) and Minecraft.
# - Docker publishes ports around ufw, so per-IP limits go in the DOCKER-USER chain.
set -euo pipefail
MC_PORT=${MC_PORT:-25565}
MAX_CONN_PER_IP=${MAX_CONN_PER_IP:-3}     # simultaneous connections per IP
NEW_PER_MIN=${NEW_PER_MIN:-10}            # new connections per IP per minute

ufw default deny incoming
ufw default allow outgoing
ufw limit 22/tcp                          # SSH: blocks IPs with 6+ hits in 30s
ufw allow "$MC_PORT"/tcp
ufw --force enable

# Flush only our chain, then re-add (idempotent). RCON 25575 is never published.
iptables -F DOCKER-USER
iptables -A DOCKER-USER -p tcp -m conntrack --ctorigdstport "$MC_PORT" --ctstate NEW \
  -m connlimit --connlimit-above "$MAX_CONN_PER_IP" --connlimit-mask 32 -j DROP
iptables -A DOCKER-USER -p tcp -m conntrack --ctorigdstport "$MC_PORT" --ctstate NEW \
  -m hashlimit --hashlimit-name mc --hashlimit-mode srcip \
  --hashlimit-above "${NEW_PER_MIN}/min" --hashlimit-burst 20 -j DROP
iptables -A DOCKER-USER -j RETURN

echo "Firewall up: SSH limited, $MC_PORT open, max $MAX_CONN_PER_IP conns & $NEW_PER_MIN new/min per IP."
echo "Persist across reboots: sudo apt install iptables-persistent && sudo netfilter-persistent save"
