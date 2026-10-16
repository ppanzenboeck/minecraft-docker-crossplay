# Minecraft Docker Crossplay Server (Minecraft 26.3)

A high-performance, containerized cross-platform Minecraft server running **Purpur 26.3** with native Java & Bedrock crossplay, real-time web maps (BlueMap & Dynmap), safe RCON interactive console access, and credentials isolation.

Runs natively on **Linux, macOS, and Windows** (with Docker Desktop, no WSL required).

---

## Features

- **Crossplay Out-of-the-Box**:
  - **Java Edition** players connect to port `25565` (TCP).
  - **Bedrock Edition** players (iOS, Android, Xbox, PlayStation, Switch, Windows 10/11) connect to port `19132` (UDP/TCP) via bundled **Geyser Standalone** and **Floodgate** (no Java account required for Bedrock players).
- **Interactive & Safe Server Console (RCON)**:
  - Cross-platform console launcher ([`console.sh`](./console.sh) / [`console.bat`](./console.bat)) powered by a lightweight Docker container.
  - Safely type server commands (`op`, `whitelist`, `say`, `save-all`). Pressing `Ctrl + C` or typing `exit` safely disconnects without killing the server.
- **Web Map Support**:
  - **BlueMap (3D WebGL real-time map)**: Active and rendered on `http://localhost:8100` and automatically exposed via a free Cloudflare HTTPS tunnel.
  - **Dynmap**: Preconfigured on port `8123` (temporarily disabled via `Dynmap.jar.disabled` until upstream publishes official 26.3 Spigot/Mojang class mappings).
- **Essential 26.3 Gameplay Plugins**:
  - **Purpur 26.3** (High-performance Paper fork with custom optimizations)
  - **OpenInv 5.3.5** (View and edit online/offline player inventories and Ender chests)
  - **DeadChest 4.31.1** (Secure death chests with timers and hologram coordinates)
  - **Multiverse-Core 5.8.1** (Multi-world management)
  - **Minepacks 2.5.7** (Personal player backpack storage)
  - **Timber 1.6.3** (Fast tree felling)
  - **LoginSecurity 3.3.0** (Password protection for accounts)
  - **ViaVersion 5.12.1** (Auto-updated client compatibility layer)
  - **Spark** (Integrated performance profiling)
- **Zero-Sudo / Userspace Accessible**:
  - Containers run with mapped `PUID=1000` and `PGID=1000`.
  - All generated worlds, logs, configs, and player data remain directly editable by your local user account without `sudo`.
- **Public Git Safe**:
  - Credentials and private keys (Playit secret token, RCON passwords, Floodgate private keys) are isolated in `credentials.txt` and `.env` (gitignored).

---

## Quick Start

### 1. Clone & Configure Credentials

Copy `credentials.example.txt` to `credentials.txt`:

```bash
# Linux / macOS
cp credentials.example.txt credentials.txt

# Windows
copy credentials.example.txt credentials.txt
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
RCON_PORT,25575
RCON_PASSWORD,your_secure_rcon_password_here
SERVER_NAME,P.A.N.Z. Crossplay Server
SERVER_MOTD,Welcome to our Minecraft 26.3 Crossplay Server!
```

> [!IMPORTANT]
> `credentials.txt` and `.env` are strictly gitignored so your personal secret tokens and passwords will never be committed or pushed to GitHub.

---

### 2. Launch the Server

| Operating System | Command |
| :--- | :--- |
| **Linux / macOS** | `./start-server.sh` |
| **Windows** | Double-click `start.bat` *(or run `start.bat` in Command Prompt / PowerShell)* |

The launch script will automatically:
1. Parse your `credentials.txt` and update `.env`.
2. Synchronize server properties and RCON configuration.
3. Synchronize Floodgate authentication keys between Paper and Geyser.
4. Launch the Docker Compose stack with auto-restart enabled (`restart: unless-stopped`).
5. Print all connection ports and the live Cloudflare BlueMap HTTPS link.

---

### 3. Server Console Management

To run administrative commands (`op <player>`, `whitelist add <player>`, `say`, `save-all`):

| Operating System | Command |
| :--- | :--- |
| **Linux / macOS** | `./console.sh` *(or use one-off: `./console.sh "op player"`)* |
| **Windows** | Double-click `console.bat` |

> [!TIP]
> Unlike `docker attach` (where pressing `Ctrl + C` sends a kill signal that shuts down Minecraft), the RCON console launcher is **100% safe**. You can press `Ctrl + C` or type `exit` at any time to return to your command prompt without disturbing the server.

---

## Ports & Web Interfaces

| Service | Port | Protocol | Description |
| :--- | :--- | :--- | :--- |
| **Java Edition** | `25565` | TCP | Main Minecraft Java server port |
| **Bedrock Edition** | `19132` | UDP / TCP | Geyser Bedrock crossplay proxy |
| **RCON Console** | `25575` | TCP | Internal remote console (`127.0.0.1` only) |
| **BlueMap 3D** | `8100` | HTTP | 3D WebGL viewer (`http://localhost:8100`) |
| **Dynmap** | `8123` | HTTP | 2D/3D map viewer (`http://localhost:8123`) |

---

## Internet Access & Tunneling

### 1. Game Server Access (Playit.gg Zero-Portforwarding)

Playit.gg creates an encrypted outbound tunnel connecting your local Docker server to Playit's global proxy network. Your router requires **zero port-forwarding**, and your personal home IP address is **never exposed**.

#### Step-by-Step Setup:
1. **Create an Account:**
   - Sign up for a free account at [playit.gg](https://playit.gg).
2. **Generate an Agent Secret Key:**
   - Log in to your Playit dashboard and navigate to **Tunnels** or **Agents**.
   - Click **Add Agent** (or choose **Docker**).
   - Playit will display a unique **Secret Key** (a 64-character hexadecimal string).
   - *(Alternative)*: If you start the server without a key, run `docker compose logs playit` to view the one-time claim URL (e.g. `https://playit.gg/claim/...`) to claim the running agent into your account automatically.
3. **Save the Key to `credentials.txt`:**
   - Open `credentials.txt` and paste your key:
     ```csv
     PLAYIT_SECRET_KEY,your_64_character_playit_secret_key_here
     ```
4. **Create the Java Edition Tunnel:**
   - On the Playit dashboard under your claimed agent, click **Add Tunnel**.
   - **Tunnel Type:** Select **Minecraft Java**.
   - **Local Port:** Enter `25565`.
   - Click **Add Tunnel**. Playit will generate a public address (e.g. `curious-panda.gl.joinmc.link`).
5. **Create the Bedrock Crossplay Tunnel:**
   - Click **Add Tunnel** again.
   - **Tunnel Type:** Select **Minecraft Bedrock**.
   - **Local Port:** Enter `19132`.
   - Click **Add Tunnel**. Playit will assign a Bedrock tunnel address with a designated public port (e.g. `curious-panda.gl.joinmc.link:38194`).
6. **Start or Restart the Server:**
   - Linux: `./start-server.sh`
   - Windows: Double-click `start.bat`
   - Check tunnel status anytime with:
     ```bash
     docker compose logs -f playit
     ```

#### How Friends Connect:
- **Java Edition (PC / Mac / Linux):**
  - Multiplayer -> Direct Connect (or Add Server).
  - Server Address: `curious-panda.gl.joinmc.link` (default port 25565 is automatically resolved by SRV records).
- **Bedrock Edition (Phones, Tablets, Consoles, Windows 10/11):**
  - Play -> Servers -> Add Server.
  - Server Name: Any name (e.g. `Crossplay Server`).
  - Server Address: `curious-panda.gl.joinmc.link`.
  - Port: Enter the specific numeric port assigned to your Bedrock tunnel by Playit (e.g. `38194`).

---

### 2. Web Map Access: Playit vs. Cloudflare Tunnels

#### Why Playit's Free Tier Cannot Host Web Maps:
- **Playit.gg free tier strictly restricts tunnels to game protocols** (Minecraft Java TCP and Bedrock UDP).
- Generic web traffic (HTTP / HTTPS / custom TCP) on ports `8100` (BlueMap) or `8123` (Dynmap) is restricted to **Playit Premium ($3 / month)**.

#### The Built-in Solution: Cloudflare Quick Tunnels (100% Free)
To provide free web map access without paid subscriptions or router port-forwarding, the stack includes a `cloudflared-bluemap` container:
- Runs automatically when the server starts.
- Creates an **encrypted public HTTPS tunnel** directly to BlueMap.
- Displays the live URL upon startup (e.g. `https://random-words.trycloudflare.com`).
- **Limitation:** Quick Tunnels are ephemeral; Cloudflare assigns a new randomized URL every time the container starts.

---

### 3. How to Set Up a Permanent / Static Map URL (Personal Domain)

If you own a domain name (or register one for ~$2–$5/year), you can use **Cloudflare Named Tunnels** for a permanent, bookmarkable URL (e.g. `https://map.yourdomain.com`) with **unlimited bandwidth for $0 forever**:

1. **Add your domain to Cloudflare:**
   - Sign up at [cloudflare.com](https://cloudflare.com) and point your domain's nameservers to Cloudflare (Free plan).
2. **Create a Cloudflare Tunnel:**
   - Go to **Cloudflare Zero Trust** dashboard -> **Networks** -> **Tunnels**.
   - Click **Create a Tunnel**, choose **Cloudflared**, and name it (e.g. `minecraft-map`).
   - Copy the tunnel token provided in the Docker command (`eyJh...`).
3. **Configure Public Hostname:**
   - In the tunnel settings, add a **Public Hostname**:
     - **Subdomain:** `map` (or `bluemap`)
     - **Domain:** `yourdomain.com`
     - **Service Type:** `HTTP`
     - **URL:** `bluemap:8100`
4. **Update `docker-compose.yml`:**
   Add your token to `credentials.txt`:
   ```csv
   CLOUDFLARE_TUNNEL_TOKEN,eyJh...
   ```
   In `docker-compose.yml`, change the `cloudflared-bluemap` command from Quick Tunnel to your named token:
   ```yaml
     cloudflared-bluemap:
       image: cloudflare/cloudflared:latest
       container_name: bluemap-tunnel
       restart: unless-stopped
       command: tunnel run --token ${CLOUDFLARE_TUNNEL_TOKEN}
   ```
5. Restart the server. Your map will be permanently accessible at `https://map.yourdomain.com` across all server reboots!

---

## Architecture & Directory Layout

```
.
├── docker-compose.yml              # Container definitions (server, geyser, bluemap, playit, cloudflared)
├── start-server.sh                 # Linux/macOS startup wrapper & credentials injector
├── start.bat                       # Windows startup wrapper (no WSL needed)
├── console.sh                      # Linux/macOS safe RCON console launcher
├── console.bat                     # Windows safe RCON console launcher
├── credentials.example.txt         # Template for server credentials (safe for git)
├── credentials.txt                 # Your private credentials & tokens (gitignored)
├── .gitignore                      # Ignore worlds, logs, secrets, and tile caches
└── rtxsurvival/                    # Minecraft server root directory
    ├── server.properties           # Main server properties (protected by skip-worktree)
    ├── purpur.yml                  # Purpur configurations
    ├── spigot.yml                  # Spigot configurations
    ├── bukkit.yml                  # Bukkit configurations
    ├── config/                     # Paper global & world configs
    ├── geyser/                     # Geyser Standalone proxy config & keys
    └── plugins/                    # Server plugins
        ├── bluemap/                # BlueMap config, data, and web assets
        ├── OpenInv.jar             # OpenInv 5.3.5 binary
        ├── dead-chest-4.31.1.jar   # DeadChest 4.31.1 binary
        ├── multiverse-core-5.8.1.jar# Multiverse-Core 5.8.1 binary
        ├── Minepacks.jar           # Minepacks 2.5.7 binary
        ├── Timber-1.6.3.jar        # Timber 1.6.3 binary
        ├── LoginSecurity-*.jar     # LoginSecurity 3.3.0 binary
        ├── ViaVersion.jar          # ViaVersion 5.12.1 binary
        ├── Floodgate-Spigot.jar    # Floodgate 2.2.5 binary
        └── Dynmap.jar.disabled     # Dynmap jar (awaiting upstream 26.3 release)
```

---

## Common Administrative Commands

- **Safe Interactive Console**:
  ```bash
  ./console.sh      # Linux / macOS
  console.bat       # Windows
  ```
- **View Live Server Logs**:
  ```bash
  docker compose logs -f server
  ```
- **View BlueMap Logs**:
  ```bash
  docker compose logs -f bluemap
  ```
- **Stop Server Safely**:
  ```bash
  docker compose down
  ```
- **Trigger BlueMap World Re-render**:
  ```bash
  docker compose exec bluemap java -jar cli.jar -r
  ```
