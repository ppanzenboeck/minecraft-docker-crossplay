# Minecraft Docker Crossplay Server (Minecraft 26.3)

A high-performance, containerized cross-platform Minecraft server running **Purpur 26.3** with native Java & Bedrock crossplay, real-time web maps (Dynmap & BlueMap), essential gameplay plugins, and safe secret credentials injection.

---

## Features

- **Crossplay Out-of-the-Box**:
  - **Java Edition** players connect to port `25565` (TCP).
  - **Bedrock Edition** players (mobile, console, Windows 10/11) connect to port `19132` (UDP/TCP) via bundled **Geyser** and **Floodgate** (no Java account required for Bedrock players).
- **Web Map Support**:
  - **BlueMap** (3D WebGL real-time map) running on `http://localhost:8100` with canonical structure in `plugins/bluemap/`.
  - **Dynmap** ready in `plugins/dynmap/` (awaiting upstream Spigot/CraftBukkit 26.3 NMS adapter release).
- **Updated Plugins (26.3 Compatible)**:
  - **Purpur 26.3** (High-performance Paper fork with custom optimizations)
  - **OpenInv 5.3.5** (View and edit online/offline player inventories and Ender chests)
  - **DeadChest** (Secure death chests with timers and hologram coordinates)
  - **Multiverse-Core 5.8.1** (Multi-world management)
  - **Minepacks** (Personal player backpack storage)
  - **Timber** (Fast tree felling)
  - **LoginSecurity** (Password protection for accounts)
  - **ViaVersion** (Auto-updated client compatibility layer)
  - **Spark** (Integrated performance profiling)
- **Zero-Sudo / Userspace Accessible**:
  - Docker containers run with mapped `PUID=1000` and `PGID=1000`.
  - All generated worlds, logs, configs, and player data remain directly editable by your local user account without requiring `sudo`.
- **Public Git Safe**:
  - Credentials and private keys (e.g. Playit.gg secret token, RCON passwords) are kept out of version control via `credentials.txt` and `.gitignore`.
  - Templated using `credentials.example.txt`.

---

## Quick Start

### 1. Clone & Configure Credentials

Copy `credentials.example.txt` to `credentials.txt`:

```bash
cp credentials.example.txt credentials.txt
```

Edit `credentials.txt` with your preferred settings:

```csv
PLAYIT_SECRET_KEY,your_playit_secret_key_here
PUID,1000
PGID,1000
MINECRAFT_VERSION,26.3
MAX_MEMORY,4096
SERVER_PORT,25565
BEDROCK_PORT,19132
DYNMAP_PORT,8123
BLUEMAP_PORT,8100
SERVER_NAME,P.A.N.Z. Crossplay Server
SERVER_MOTD,Welcome to our Minecraft 26.3 Crossplay Server!
```

> **Note**: `credentials.txt` is gitignored so your secret keys and IP configs will never be committed or pushed to GitHub.

### 2. Launch the Server

Run the launch script:

```bash
./start-server.sh
```

The script will:
1. Parse your `credentials.txt` (CSV / KEY=VALUE format).
2. Export variables to `.env` and synchronize `rtxsurvival/server.properties`.
3. Verify directory permissions (`PUID:PGID`).
4. Launch the Docker Compose services in the background.

---

## Ports & Web Interfaces

| Service | Port | Protocol | Description |
| :--- | :--- | :--- | :--- |
| **Java Edition** | `25565` | TCP | Main Minecraft Java server port |
| **Bedrock Edition** | `19132` | UDP / TCP | Geyser Bedrock crossplay proxy |
| **Dynmap** | `8123` | HTTP | 2D/3D map viewer (`http://localhost:8123`) |
| **BlueMap** | `8100` | HTTP | 3D WebGL viewer (`http://localhost:8100`) |

---

## Architecture & Directory Layout

```
.
├── docker-compose.yml              # Container definitions (server, geyser, bluemap, playit)
├── start-server.sh                 # Startup wrapper & credentials injector
├── credentials.example.txt         # Template for server credentials (safe for git)
├── credentials.txt                 # Your private credentials (gitignored)
├── .gitignore                      # Ignore worlds, logs, secrets, and tile caches
└── rtxsurvival/                    # Minecraft server root directory
    ├── server.properties           # Main server properties
    ├── purpur.yml                  # Purpur configurations
    ├── spigot.yml                  # Spigot configurations
    ├── bukkit.yml                  # Bukkit configurations
    ├── config/                     # Paper global & world configs
    ├── geyser/                     # Geyser Standalone proxy config & packs
    └── plugins/                    # Server plugins
        ├── bluemap/                # BlueMap config, data, and web files
        ├── OpenInv.jar             # OpenInv 5.3.5 binary
        ├── dead-chest-4.31.0.jar   # DeadChest 4.31.0 binary
        ├── multiverse-core-5.8.1.jar# Multiverse-Core 5.8.1 binary
        ├── Minepacks.jar           # Minepacks 2.5.7 binary
        ├── Timber-1.6.3.jar        # Timber 1.6.3 binary
        ├── LoginSecurity-*.jar     # LoginSecurity 3.3.0 binary
        ├── ViaVersion.jar          # ViaVersion 5.12.1 binary
        └── Floodgate-Spigot.jar    # Floodgate 2.2.5 binary
```

---

## External Access (Playit.gg Tunnel)

If you don't have a public IPv4 address or cannot port forward on your router:
1. Create a free account at [playit.gg](https://playit.gg).
2. Generate an agent secret key.
3. Add the key to `credentials.txt`:
   ```csv
   PLAYIT_SECRET_KEY,your_secret_key_from_playit
   ```
4. Restart the server (`./start-server.sh`). The playit agent will tunnel your Java and Bedrock ports automatically.

---

## Useful Commands

- **View live server console logs**:
  ```bash
  docker compose logs -f server
  ```
- **Attach to Minecraft console** (type commands directly):
  ```bash
  docker attach server
  ```
  *(Press `Ctrl+P` followed by `Ctrl+Q` to detach without stopping the server)*
- **Stop the server safely**:
  ```bash
  docker compose down
  ```
- **Trigger BlueMap full render**:
  ```bash
  docker compose exec bluemap java -jar cli.jar -r
  ```
- **Trigger Dynmap full render**:
  In the Minecraft server console (or as op in-game):
  ```
  dynmap fullrender world
  ```

---

## System Requirements & Notes for Arch Linux / Other Hosts

- **Docker & Docker Compose**: Ensure `docker` and `docker-compose` (or `docker compose` plugin) are installed and the current user is added to the `docker` group (`sudo usermod -aG docker $USER`).
- **User IDs**: On Arch Linux and most distributions, the default user is `UID=1000` / `GID=1000`. The server startup wrapper ensures files created by Docker remain fully owned by your user account.
