# Stage 12 — Co-op Multiplayer Foundation

## Architecture
Use Nakama with PostgreSQL for dedicated authoritative sessions. Offline single-player remains independent and does not require an account or network connection.

## Implemented in the repository
- Docker Compose stack for Nakama 3.22.0 and PostgreSQL 16.
- Lua authoritative match handler with a four-player cap, server-owned position/yaw state, bounded movement intents, 10 Hz state simulation and host marker reassignment.
- Authenticated server RPC `create_coop_match` creates the registered authoritative match.
- Godot co-op client autoload supports device authentication, WebSocket connection, create-match RPC, join-by-match-ID, sending bounded movement input, receiving authoritative state, leaving and disconnecting.
- `config/coop_server.json` defines the server endpoint, API key, match RPC and protocol opcodes. The local loopback endpoint is a development default, not a public production address.
- Pause-menu Co-op Multiplayer panel provides connect, create-session, join-by-Match-ID and disconnect actions. The world sends local movement intents and renders remote survivor placeholders from state broadcasts.

## Dashboard isolation rule
The private Admin/Personal Dashboard is a completely separate application. It is not part of this co-op lobby and must never appear in the player dashboard, pause menu, lobby, settings, profile, inventory, maps or any other in-game screen. No game-client route, button, link, overlay or deep link may open it. The game client must not bundle its files or privileged credentials.

## Deployment and key handling
1. Deploy Nakama + PostgreSQL on a dedicated Linux server.
2. Configure `NAKAMA_DB_PASSWORD` as a private database credential.
3. Configure `NAKAMA_SERVER_KEY` to the same Nakama API key configured in the client. The Nakama server key is a client-visible API key, not a database password; protect the database password and administrative interfaces separately.
4. Keep PostgreSQL and Nakama console private. Put a TLS reverse proxy in front of the public client endpoints.
5. Verify the Lua runtime module is loaded and the `create_coop_match` RPC is registered before clients connect.

## Remaining before playable co-op
- Validate the Godot transport against a deployed Nakama server; the current client/server exchange has not been runtime-tested.
- Add invite/share-code UX, lobby ready state, reconnect/resume and graceful session cleanup.
- Replicate player transforms with smooth interpolation and animation; add authoritative monster, combat, health, loot and inventory simulation.
- Add matchmaking, rate limits, abuse controls, server monitoring and operational backups.
- Run 2–4 physical clients through latency, disconnect, reconnect, match-full and exploit tests.
- Provision and secure a real public server; no server is deployed by these repository commits.

## Release gate
Co-op remains Coming Soon and cannot be advertised as playable until client gameplay integration, dedicated server deployment, security review and multi-device QA pass.
