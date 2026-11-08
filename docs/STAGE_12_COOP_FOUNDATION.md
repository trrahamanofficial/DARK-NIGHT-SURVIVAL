# Stage 12 — Co-op Multiplayer Foundation

## Architecture
Use Nakama with PostgreSQL for dedicated authoritative sessions. Do not use Supabase Realtime or a static website host as the game simulation authority. Offline single-player remains independent.

## First foundation pass
- Added a pinned Docker Compose stack for Nakama 3.22.0 and PostgreSQL 16.
- Added a Lua authoritative match handler.
- Sessions are capped at four players.
- Clients submit bounded movement intents; the server owns and broadcasts canonical position/yaw state at 10 Hz.
- Disconnect removes a presence and reassigns the session host marker.
- Secrets are environment-provided and not committed; ports bind to loopback by default.

## Not yet implemented
Godot socket authentication and client transport; co-op lobby, invite, create/join and ready UI; reconnect/resume; authoritative monster/combat/health/loot simulation; matchmaking, rate limiting, moderation, TLS/public deployment and cost controls; multi-client latency, disconnect, abuse and security tests.

## Release gate
Co-op stays Coming Soon and unavailable until client integration, dedicated server deployment, security review and 2–4 client gameplay tests pass.
