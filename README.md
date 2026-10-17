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
| **Windows** | Double-click `start-server.bat` *(or run `start-server.bat` in Command Prompt / PowerShell)* |

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

## Connecting to the Server

### 1. Local Network / LAN Connection (Playing on the Same Home Network)

If you are playing on the machine hosting the server, or from another computer/laptop/phone connected to the same home Wi-Fi network, you **do not need Playit.gg or any internet tunnels**.

#### A. Playing on the Host Machine (Same PC running Docker):
- **Java Edition:** Direct Connect to `localhost` (or `127.0.0.1:25565`).
- **Bedrock Edition:** Add Server with Address `127.0.0.1` and Port `19132`.
- **BlueMap Web Map:** Open your browser to `http://localhost:8100`.

#### B. Playing from Another Device on Same Wi-Fi (e.g. Laptop, Phone, Tablet):
To connect from another device in your home, use the **local IP address** of the host PC running Docker (e.g. `192.168.1.10`).

1. **Find Your Host PC's Local IP Address:**
   - **Linux (Any distribution including minimal Arch):** Open terminal and run:
     ```bash
     ip address
     ```
     Look for the line starting with `inet` under your active Ethernet or Wi-Fi interface (typically `192.168.x.x` or `10.0.0.x`; ignore `127.0.0.1` loopback and `docker0` / `172.x` virtual bridges).
   - **Windows:** Open Command Prompt or PowerShell and run:
     ```cmd
     ipconfig
     ```
     Look for `IPv4 Address` under your active Wi-Fi or Ethernet adapter (e.g. `192.168.1.10`).

   > [!TIP]
   > **Quick One-Liner Filters:**  
   > If you want to filter the output down directly to your local IPv4 address line:
   > - **Linux:**
   >   ```bash
   >   ip address | grep "scope global" | grep -v "docker0"
   >   ```
   > - **Windows:**
   >   ```cmd
   >   ipconfig | findstr /i "IPv4"
   >   ```

2. **Connect from Your Laptop or Mobile Device:**
   - **Java Edition:** In Multiplayer -> Direct Connect (or Add Server), enter:
     ```
     192.168.1.10:25565
     ```
     *(or just `192.168.1.10` since 25565 is the default Minecraft port).*
   - **Bedrock Edition:** In Play -> Servers -> Add Server, enter:
     - **Server Name:** `Home Server`
     - **Server Address:** `192.168.1.10`
     - **Port:** `19132` (the standard Bedrock default port).
   - **BlueMap 3D Map:** Open any browser on your laptop or phone:
     ```
     http://192.168.1.10:8100
     ```

> [!TIP]
> **Firewall Note:** If connection times out from another local device, check that the host PC firewall permits local incoming connections:
> - **Windows:** If prompted by Windows Defender Firewall, check **"Allow on Private networks"**.
> - **Linux:** If using `ufw`, allow local subnet traffic (e.g., `sudo ufw allow 25565/tcp && sudo ufw allow 19132/udp && sudo ufw allow 8100/tcp`).

---

## Internet Access & Tunneling

### 2. Game Server Access (Playit.gg Zero-Portforwarding)

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
   - Windows: Double-click `start-server.bat`
   - Check tunnel status anytime with:
     ```bash
     docker compose logs -f playit
     ```

#### How Friends Connect:
- **Java Edition (PC / Mac / Linux):**
  - Multiplayer -> Direct Connect (or Add Server).
  - Server Address: `curious-panda.gl.joinmc.link` (default port 25565 is automatically resolved by SRV records).
- **Bedrock Edition (Phones, Tablets, Windows 10/11):**
  - Play -> Servers -> Add Server.
  - Server Name: Any name (e.g. `Crossplay Server`).
  - Server Address: `curious-panda.gl.joinmc.link`.
  - Port: Enter the specific numeric port assigned to your Bedrock tunnel by Playit (e.g. `38194`).

---

### Platform Compatibility & Tested Devices

> [!NOTE]
> This server has been **actively tested and verified on PC** (Linux & Windows Java Edition, and Windows 10/11 Bedrock Edition). Mobile and console compatibility are detailed below:

| Platform | Status | Connection Method & Requirements |
| :--- | :--- | :--- |
| **PC (Java)** | **Verified** | Native "Direct Connect" / "Add Server" in Minecraft Java. |
| **PC (Windows 10/11 Bedrock)** | **Verified** | Built-in "Add Server" button in Bedrock menu. |
| **Mobile (iOS & Android)** | **Supported** | Built-in "Add Server" button in Bedrock menu. |
| **Nintendo Switch (& Switch 2)** | **Supported\*** | Requires **Nintendo Switch Online (NSO)** subscription (Nintendo blocks joining external or even local multiplayer without NSO) + BedrockConnect DNS workaround. |
| **PlayStation (PS4 / PS5)** | **Supported\*** | Requires **PlayStation Plus** + BedrockConnect DNS workaround. |
| **Xbox (One, Series S/X)** | **Supported\*** | Requires **Xbox Game Pass Core** + BedrockConnect DNS workaround. |

#### \* Note on Consoles (Switch, PlayStation, Xbox):
Console editions of Minecraft do not include the "Add External Server" button by default (restricted by console platform policies). To connect a console to a custom Bedrock server:
1. **BedrockConnect (DNS Method):** Set your console's Primary DNS in Network Settings to a public BedrockConnect resolver (such as `104.238.130.180`). When you click any official "Featured Server" in Minecraft, BedrockConnect will open a custom menu letting you enter your Playit server address and port.
2. **LAN Proxy Apps:** Alternatively, run a free mobile tool (such as *MC Server Connector* on Android/iOS) on the same home Wi-Fi network. The app broadcasts the server locally so it appears directly under the console's **Friends / LAN Games** tab.

---

### 2. Web Map Access: Playit vs. Cloudflare Tunnels

#### Why Playit's Free Tier Focuses on Game Protocols:
- **Playit.gg free tier is optimized specifically for game traffic** (Minecraft Java TCP and Bedrock UDP).
- Generic web routing (HTTP / HTTPS / custom TCP) on ports `8100` (BlueMap) or `8123` (Dynmap) is an optional feature available for cheap (visit [playit.gg](https://playit.gg/) for current tiers and plan details).

#### The Built-in Solution: Cloudflare Quick Tunnels (100% Free)
To provide free web map access without paid subscriptions or router port-forwarding, the stack includes a `cloudflared-bluemap` container:
- Runs automatically when the server starts.
- Creates an **encrypted public HTTPS tunnel** directly to BlueMap.
- Displays the live URL upon startup (e.g. `https://random-words.trycloudflare.com`).
- **Note:** Quick Tunnels are ephemeral; Cloudflare assigns a new randomized URL whenever the container restarts.

---

### 3. How to Set Up a Permanent / Static Map URL (Personal Domain)

If you own a domain name, you can configure **Cloudflare Named Tunnels** for a permanent, bookmarkable URL (e.g. `https://map.yourdomain.com`) with zero hosting fees:

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

## Advanced Administration & Customization

### 1. Bedrock Player Administration (Floodgate Prefix & Linking)

Because Bedrock Edition allows Xbox Gamertags that may contain spaces or clash with Java account names, **Floodgate** automatically prefixes all Bedrock player names with a dot (`.`):

- **Targeting Bedrock Players in Console:**
  When executing commands via `./console.sh`, `console.bat`, or in-game, you must include the dot prefix:
  ```
  op .GamerTag
  whitelist add .GamerTag
  gamemode creative .GamerTag
  ```
- **Xbox Gamertags With Spaces:**
  If a Bedrock player's Gamertag contains spaces (e.g. `Cool Miner 99`), wrap the name in quotation marks:
  ```
  op ".Cool Miner 99"
  whitelist add ".Cool Miner 99"
  ```
- **Account Linking (Optional):**
  If a player owns both Java and Bedrock editions, they can link them by running `/linkaccount` in-game so inventories, permissions, and skins stay synced across both devices.

---

### 2. Memory Tuning Guide (`MAX_MEMORY`)

You can control how much RAM is allocated to Minecraft directly in `credentials.txt` via `MAX_MEMORY` (measured in megabytes):

```csv
MAX_MEMORY,4096
```

#### Recommended Allocations:
| `MAX_MEMORY` Value | RAM (MB) | Best For |
| :--- | :--- | :--- |
| **`2048`** | 2 GB | Laptops or low-spec hosts with 4–8 GB total system RAM (2–4 players). |
| **`4096`** *(Default)* | 4 GB | Balanced setup for 5–10 players exploring standard worlds and using web maps. |
| **`6144`** | 6 GB | Active multiplayer servers (10–15 players) with concurrent world renders. |
| **`8192`** | 8 GB | High-spec hosts (16–32 GB system RAM) running heavy chunk generation or large groups. |

> [!NOTE]
> After modifying `MAX_MEMORY` in `credentials.txt`, restart the server (`./start-server.sh` or `start-server.bat`) to apply the new Java heap limits.

---

### 3. World Migration & Backups (Importing Your Own World)

Because world files are gitignored to keep the repository clean and light, you can import an existing singleplayer world or migrate from another server anytime:

1. **Stop the Server:**
   ```bash
   docker compose down
   ```
2. **Copy Overworld Files:**
   - Copy your singleplayer world contents (`region/`, `entities/`, `data/`, `level.dat`) into `data/world/`.
3. **Migrate Nether & The End (Paper Directory Structure):**
   - Singleplayer Minecraft stores the Nether in `world/DIM-1/` and The End in `world/DIM1/`.
   - Paper/Purpur separates them into distinct root directories:
     - Move the contents of `DIM-1/` into `data/world_nether/DIM-1/`.
     - Move the contents of `DIM1/` into `data/world_the_end/DIM1/`.
4. **Re-render the 3D Web Map:**
   After starting the server, run:
   ```bash
   docker compose exec bluemap java -jar cli.jar -r
   ```
   BlueMap will scan the new world chunks and update your live map.

---

## Architecture & Directory Layout

```
.
├── docker-compose.yml              # Container definitions (server, geyser, bluemap, playit, cloudflared)
├── start-server.sh                 # Linux/macOS startup wrapper & credentials injector
├── start-server.bat                # Windows startup wrapper (no WSL needed)
├── console.sh                      # Linux/macOS safe RCON console launcher
├── console.bat                     # Windows safe RCON console launcher
├── credentials.example.txt         # Template for server credentials (safe for git)
├── credentials.txt                 # Your private credentials & tokens (gitignored)
├── .gitignore                      # Ignore worlds, logs, secrets, and tile caches
└── data/                           # Minecraft server root directory
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

---

## Credits & Acknowledgements

This project orchestrates and builds upon incredible open-source tools created by the Minecraft server community:

- **Base Docker Image**: [James Chambers (`05jchambers`)](https://github.com/TheRemote/Legendary-Minecraft-Purpur-Geyser) for the [`legendary-minecraft-purpur-geyser`](https://hub.docker.com/r/05jchambers/legendary-minecraft-purpur-geyser) container base.
- **Server Software**:
  - [PurpurMC](https://purpurmc.org/) — High-performance, customizable Paper fork.
  - [PaperMC](https://papermc.io/) — Next-generation Minecraft gameplay server engine.
- **Crossplay Engine**:
  - [GeyserMC](https://geysermc.org/) — Bedrock-to-Java protocol translation bridge ([Geyser Standalone](https://github.com/GeyserMC/Geyser)).
  - [Floodgate](https://github.com/GeyserMC/Floodgate) — Hybrid Java authentication without requiring a Java account.
- **Web Maps & Visualization**:
  - [BlueMap](https://bluemap.bluecolored.de/) — Real-time 3D WebGL Minecraft map generator.
  - [Dynmap](https://github.com/webbukkit/dynmap) — Web map system for Spigot / Paper.
- **Gameplay Plugins & Authors**:
  - **DeadChest**: [Stellionix](https://github.com/Stellionix/Deadchest) — Safe player grave inventories with hologram markers.
  - **LoginSecurity**: [lenis0012](https://github.com/lenis0012/LoginSecurity-2) — Account authentication and password management.
  - **OpenInv**: [Jikoo](https://github.com/Jikoo/OpenInv) — Real-time inventory and Ender chest management.
  - **Multiverse-Core**: [The Multiverse Team](https://github.com/Multiverse/Multiverse-Core) — Multi-world generator and dimension manager.
  - **Minepacks**: [GeorgH93](https://github.com/GeorgH93/Minepacks) — Backpack storage system.
  - **Timber**: [Imperialroma10 (Roman43435)](https://www.spigotmc.org/resources/timber-1-13-1-20-4.113160/) — Fast tree felling utility.
  - **ViaVersion & ViaBackwards**: [ViaVersion Team](https://github.com/ViaVersion) — Client version backward compatibility.
  - **Spark**: [Luck (lucko)](https://spark.lucko.me/) — In-depth server performance profiler.
- **Networking & Tunnels**:
  - [Cloudflare](https://www.cloudflare.com/) — Secure quick and named application tunnels via `cloudflared`.
  - [Playit.gg](https://playit.gg/) — Low-latency game tunnel infrastructure.
  - [itzg/rcon-cli](https://github.com/itzg/rcon-cli) — Lightweight RCON terminal client.

---

## Legal & Trademarks

- **Not an official Minecraft product.** Not approved by or associated with Mojang or Microsoft.
- Minecraft and related brand assets are registered trademarks of Mojang AB and Microsoft Corporation.
- All bundled plugins, tools, and libraries remain the intellectual property of their respective creators under their open-source licenses (GPL, Apache 2.0, MIT, and BSD).
- The orchestration scripts, container configurations, and documentation in this repository are licensed under the [MIT License](LICENSE).

