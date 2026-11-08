# DARK NIGHT: SURVIVAL — Co-op Server

## Stage 12 foundation
Selected architecture: Nakama + PostgreSQL with server-authoritative match state. Offline single-player remains independent of this service.

### Included
- Docker Compose stack: Nakama 3.22.0 and PostgreSQL 16.
- `modules/dark_night_match.lua`: four-player authoritative match, bounded client movement intents, 10 Hz server state and host marker reassignment.
- Authenticated RPC `create_coop_match` to create the registered match module.
- Godot-side connection/authentication and realtime transport: `scripts/coop_client.gd`.
- Client endpoint/protocol configuration: `config/coop_server.json`.

## Deployment outline
1. Install Docker Engine and Docker Compose on a Linux server.
2. Set a strong private `NAKAMA_DB_PASSWORD`.
3. Set `NAKAMA_SERVER_KEY` to the same client API key configured in `config/coop_server.json`. This API key is client-visible; it is not the database password.
4. Keep PostgreSQL and Nakama's administrative console private. Put a TLS reverse proxy in front before exposing client endpoints.
5. Run `docker compose up -d`, inspect logs, and verify the Lua runtime module and RPC registration.

## Important limitations
This is a multiplayer integration foundation, not a playable online co-op release. No public server has been provisioned or deployed.
The in-game lobby/player presentation, invites/share codes, reconnect/resume, authoritative monsters/combat/health/loot, matchmaking, abuse controls, TLS deployment, backups and multi-client QA remain.
The current handler is a minimal authoritative movement-state prototype, not a complete anti-cheat system.
Co-op remains Coming Soon until client gameplay integration, server deployment, security review and 2–4 client gameplay tests pass.
