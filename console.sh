#!/usr/bin/env bash
# ==============================================================================
# Crossplay Minecraft Server - Interactive Console Client (RCON)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
CREDENTIALS_FILE="${SCRIPT_DIR}/credentials.txt"

RCON_PORT="25575"
RCON_PASSWORD=""

# Read configuration from .env or credentials.txt
target_file=""
if [ -f "${ENV_FILE}" ]; then
  target_file="${ENV_FILE}"
elif [ -f "${CREDENTIALS_FILE}" ]; then
  target_file="${CREDENTIALS_FILE}"
fi

if [ -n "${target_file}" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$line" == *","* ]]; then
      k="${line%%,*}"
      v="${line#*,}"
    elif [[ "$line" == *"="* ]]; then
      k="${line%%=*}"
      v="${line#*=}"
    else
      continue
    fi
    k="$(echo "$k" | tr -d '[:space:]')"
    v="$(echo "$v" | tr -d '[:space:]')"
    [ "$k" = "RCON_PORT" ] && [ -n "$v" ] && RCON_PORT="$v"
    [ "$k" = "RCON_PASSWORD" ] && [ -n "$v" ] && RCON_PASSWORD="$v"
  done < "${target_file}"
fi

if [ -z "${RCON_PASSWORD}" ]; then
  echo "[-] Error: RCON_PASSWORD is not configured in credentials.txt or .env" >&2
  echo "    Please set RCON_PASSWORD in credentials.txt and restart the server." >&2
  exit 1
fi

echo "[*] Connecting to Minecraft RCON console on port ${RCON_PORT}..."
echo "    (Type commands directly. Press Ctrl+C or type 'exit' to disconnect without stopping the server.)"
echo ""

exec docker run -it --rm --network host itzg/rcon-cli:latest --port "${RCON_PORT}" --password "${RCON_PASSWORD}" "$@"
