# Separate Admin Dashboard

This directory is reserved for a standalone dashboard application. It is intentionally not bundled into the Godot game client.

Security requirements before implementation:
- Separate deployment origin from the game.
- Require authenticated admin access and server-side role authorization.
- Keep privileged secrets in server-side environment variables only.
- Never store admin passwords or service-role keys in this repository or game client.
- Record sensitive administrative changes in an audit log.
- Do not expose public player-facing routes to dashboard-only actions.

Status: architecture placeholder only; dashboard UI, authentication and backend are scheduled for a later implementation stage.
