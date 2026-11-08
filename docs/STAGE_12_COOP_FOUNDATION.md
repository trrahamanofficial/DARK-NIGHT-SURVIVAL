# Stage 12 — Co-op Multiplayer Foundation

## Architecture
Use Nakama with PostgreSQL for dedicated authoritative sessions. Offline single-player remains independent and does not require an account or network connection.

## Implemented in the repository
- Docker Compose stack for Nakama 3.22.0 and PostgreSQL 16.
- Lua authoritative match handler with a four-player cap, server-owned position/yaw state, bounded movement intents, 10 Hz state simulation and host marker reassignment.
- Authenticated server RPC `create_coop_match` creates the registered authoritative match.
- Godot co-op client autoload supports device authentication, WebSocket connection, create-match RPC, join-by-match-ID, sending bounded movement input, receiving authoritative state, leaving and disconnecting.
- `config/coop_server.json` defines the server endpoint, API key, match RPC and protocol opcodes. The local loopback endpoint is a development default, not a public production address.
- Co-op remains disabled/Coming Soon in the game until a real server is deployed and the remaining release gates pass.

## Deployment and key handling
1. Deploy Nakama + PostgreSQL on a dedicated Linux server.
2. Configure `NAKAMA_DB_PASSWORD` as a private database credential.
3. Configure `NAKAMA_SERVER_KEY` to the same Nakama API key configured in the client. The Nakama server key is a client-visible API key, not a database password; protect the database password and administrative interfaces separately.
4. Keep PostgreSQL and Nakama console private. Put a TLS reverse proxy in front of the public client endpoints.
5. Verify the Lua runtime module is loaded and the `create_coop_match` RPC is registered before clients connect.

## Remaining before playable co-op
- Connect this client transport to the in-game lobby and player presentation.
- Add invite/share-code UX, lobby ready state, reconnect/resume and graceful session cleanup.
- Replicate player transforms and animation; add authoritative monster, combat, health, loot and inventory simulation.
- Add matchmaking, rate limits, abuse controls, server monitoring and operational backups.
- Run 2–4 physical clients through latency, disconnect, reconnect, match-full and exploit tests.
- Provision and secure a real public server; no server is deployed by these repository commits.

## Release gate
Co-op remains Coming Soon and cannot be advertised as playable until client gameplay integration, dedicated server deployment, security review and multi-device QA pass.


## Additional in-game integration pass
- Added a pause-menu Co-op Multiplayer panel with connect, create-session, join-by-Match-ID and disconnect actions.
- The world now sends local movement intents while a match is active and renders remote survivor placeholders from authoritative state broadcasts; departed peers are cleaned up.
- This is still an integration prototype: player spawn reconciliation, smooth interpolation, animation, lobby ready/invite flow, combat/monster authority and real server testing remain.
- Latest Android, Windows and Web export workflows were triggered for source commit 88480a80d844178e086431a091b814b008f38b5b; results must be checked before marking builds green.
