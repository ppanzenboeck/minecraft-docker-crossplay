#!/usr/bin/env bash
# ==============================================================================
# Crossplay Minecraft Server - Launch & Credentials Injection Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

CREDENTIALS_FILE="${SCRIPT_DIR}/credentials.txt"
TEMPLATE_FILE="${SCRIPT_DIR}/credentials.example.txt"
ENV_FILE="${SCRIPT_DIR}/.env"
SERVER_PROPS="${SCRIPT_DIR}/rtxsurvival/server.properties"

# Ensure credentials.txt exists
if [ ! -f "${CREDENTIALS_FILE}" ]; then
  if [ -f "${TEMPLATE_FILE}" ]; then
    echo "[!] No credentials.txt found. Creating one from credentials.example.txt..."
    cp "${TEMPLATE_FILE}" "${CREDENTIALS_FILE}"
    echo "[!] Created ${CREDENTIALS_FILE}. Please edit it with your secrets if needed."
  else
    echo "[!] Error: Neither credentials.txt nor credentials.example.txt found!" >&2
    exit 1
  fi
fi

echo "[*] Loading credentials and settings from credentials.txt..."

# Clear/create .env file
rm -f "${ENV_FILE}"
touch "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

# Parse CSV / KEY=VALUE format and export into .env
while IFS= read -r line || [ -n "$line" ]; do
  # Strip leading/trailing whitespace
  line="$(echo "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # Skip blank lines and comments
  if [[ -z "${line}" ]] || [[ "${line}" =~ ^# ]]; then
    continue
  fi

  # Support both comma-separated (KEY,VALUE) and equals (KEY=VALUE)
  if [[ "${line}" == *","* ]]; then
    key="${line%%,*}"
    val="${line#*,}"
  elif [[ "${line}" == *"="* ]]; then
    key="${line%%=*}"
    val="${line#*=}"
  else
    continue
  fi

  key="$(echo "${key}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  val="$(echo "${val}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # Export to environment and write to .env
  export "${key}=${val}"
  echo "${key}=${val}" >> "${ENV_FILE}"
done < "${CREDENTIALS_FILE}"

# Set default fallbacks if missing
PUID="${PUID:-$(id -u)}"
PGID="${PGID:-$(id -g)}"
MINECRAFT_VERSION="${MINECRAFT_VERSION:-26.3}"
MAX_MEMORY="${MAX_MEMORY:-4096}"
SERVER_PORT="${SERVER_PORT:-25565}"
BEDROCK_PORT="${BEDROCK_PORT:-19132}"
DYNMAP_PORT="${DYNMAP_PORT:-8123}"
BLUEMAP_PORT="${BLUEMAP_PORT:-8100}"
PLAYIT_SECRET_KEY="${PLAYIT_SECRET_KEY:-}"

# Update .env with resolved defaults
echo "PUID=${PUID}" >> "${ENV_FILE}"
echo "PGID=${PGID}" >> "${ENV_FILE}"
echo "MINECRAFT_VERSION=${MINECRAFT_VERSION}" >> "${ENV_FILE}"
echo "MAX_MEMORY=${MAX_MEMORY}" >> "${ENV_FILE}"
echo "SERVER_PORT=${SERVER_PORT}" >> "${ENV_FILE}"
echo "BEDROCK_PORT=${BEDROCK_PORT}" >> "${ENV_FILE}"
echo "DYNMAP_PORT=${DYNMAP_PORT}" >> "${ENV_FILE}"
echo "BLUEMAP_PORT=${BLUEMAP_PORT}" >> "${ENV_FILE}"

# Inject properties into server.properties if present
if [ -f "${SERVER_PROPS}" ]; then
  echo "[*] Injecting configuration into server.properties..."
  
  update_prop() {
    local prop="$1"
    local value="$2"
    if [ -n "${value}" ]; then
      if grep -q "^${prop}=" "${SERVER_PROPS}"; then
        sed -i "s|^${prop}=.*|${prop}=${value}|" "${SERVER_PROPS}"
      else
        echo "${prop}=${value}" >> "${SERVER_PROPS}"
      fi
    fi
  }

  update_prop "server-port" "${SERVER_PORT}"
  update_prop "query.port" "${SERVER_PORT}"
  update_prop "server-name" "${SERVER_NAME:-P.A.N.Z. Crossplay Server}"
  update_prop "motd" "${SERVER_MOTD:-Welcome to Minecraft 26.3 Purpur Crossplay Server!}"
  [ -n "${RCON_PASSWORD:-}" ] && update_prop "rcon.password" "${RCON_PASSWORD}"
  [ -n "${MANAGEMENT_SERVER_SECRET:-}" ] && update_prop "management-server-secret" "${MANAGEMENT_SERVER_SECRET}"
fi

# Ensure canonical plugin and proxy directories exist
mkdir -p rtxsurvival/plugins/dynmap rtxsurvival/plugins/bluemap/config rtxsurvival/plugins/bluemap/data rtxsurvival/plugins/bluemap/web rtxsurvival/geyser

# Sync Floodgate authentication key to Geyser Standalone proxy
if [ -f "rtxsurvival/plugins/floodgate/key.pem" ] && [ ! -f "rtxsurvival/geyser/key.pem" ]; then
  echo "[*] Syncing Floodgate key.pem to Geyser..."
  cp "rtxsurvival/plugins/floodgate/key.pem" "rtxsurvival/geyser/key.pem"
fi

echo "[*] Starting containers with Docker Compose..."
docker compose up -d

echo ""
echo "=================================================================="
echo " Minecraft Crossplay Server Started Successfully!"
echo "=================================================================="
echo " - Version: Purpur ${MINECRAFT_VERSION}"
echo " - Java Edition Port:    ${SERVER_PORT} (TCP)"
echo " - Bedrock Edition Port: ${BEDROCK_PORT} (UDP/TCP)"
echo " - Dynmap Web Map:       http://localhost:${DYNMAP_PORT}"
echo " - BlueMap 3D Web Map:   http://localhost:${BLUEMAP_PORT}"
if [ -n "${PLAYIT_SECRET_KEY}" ] && [ "${PLAYIT_SECRET_KEY}" != "your_playit_secret_key_here" ]; then
  echo " - Playit Tunnel:        Enabled (monitoring tunnel in background)"
else
  echo " - Playit Tunnel:        No secret key provided (local access only)"
fi
echo "=================================================================="
echo " To view server logs:    docker compose logs -f server"
echo " To view bluemap logs:   docker compose logs -f bluemap"
echo " To stop the server:     docker compose down"
echo "=================================================================="
