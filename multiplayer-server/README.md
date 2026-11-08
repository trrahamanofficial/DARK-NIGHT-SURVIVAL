# DARK NIGHT: SURVIVAL — Co-op Server

## Stage 12 foundation
Selected architecture: Nakama + PostgreSQL with server-authoritative match state. Offline single-player remains independent of this service.

### Included
- docker-compose.yml: Nakama 3.22.0 and PostgreSQL 16; credentials are supplied through environment variables and are never committed.
- modules/dark_night_match.lua: match handler with a four-player cap, server-owned position/yaw state, bounded input intents, fixed 10 Hz simulation, state broadcasts, and host reassignment after disconnect.
- Protocol identifiers: client input opcode 1; authoritative state opcode 2; protocol version 1.

## Deployment outline
1. Install Docker Engine and Docker Compose on a Linux server.
2. Set strong unique NAKAMA_DB_PASSWORD and NAKAMA_SERVER_KEY environment variables outside source control.
3. Keep ports private initially. Put a TLS reverse proxy in front before exposing clients.
4. Run docker compose up -d and inspect logs/health before connecting a client.
5. Never expose PostgreSQL or the Nakama administrative console publicly. Never place the server key in a game client.

## Important limitations
This is a server foundation, not a playable online co-op release. No public server has been provisioned or deployed.
Godot client authentication, lobby/create/join UI, reconnect/resume, replicated character presentation, authoritative combat/loot, matchmaking, abuse controls, TLS deployment and multi-client network tests remain.
The current handler is a minimal authoritative movement-state prototype, not a complete anti-cheat system. It does not yet simulate monsters, weapons, health or inventory.
Co-op must remain Coming Soon until all client/server integration and real multi-device tests pass.
