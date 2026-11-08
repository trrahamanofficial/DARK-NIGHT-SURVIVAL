# Private Admin / Personal Dashboard (Separate Application)

## Non-negotiable visibility rule
This dashboard is private and separate from the game. It must NEVER appear in:
- the player dashboard or main game screen;
- the pause menu, co-op lobby, matchmaking or session screens;
- game Settings, profile, inventory, maps or any other player-facing screen;
- Android, Windows or Web game exports.

There must be no in-game button, link, route, deep link, overlay, menu item or hint that opens this dashboard. The game client must not bundle this application.

## Deployment boundary
- Deploy this application on its own origin, separate from the game and multiplayer server.
- Do not add a dashboard link to the game website or game UI.
- Require authenticated admin login and enforce the admin role on the server for every privileged operation.
- Use database Row Level Security / server-side authorization; hiding UI controls is not security.
- Keep service-role keys, database credentials and other privileged secrets on the server only. Never put them in game exports or browser JavaScript.
- Log privileged changes with actor, timestamp, action and target.
- Deny access by default. A normal player account must never gain admin access.

## Current implementation status
This folder is an architecture/security boundary, not a completed dashboard. The UI, authentication integration, protected API and audit log are not yet implemented or deployed. Do not describe the dashboard as live until those pieces and a separate-origin access test pass.

## Release acceptance tests
1. Search all game scenes, scripts and exported UI for dashboard/admin links and controls; expected result: none.
2. Open every player screen (main game, pause, co-op lobby, settings, profile, inventory); expected result: no dashboard reference.
3. Attempt dashboard access while logged out and as a normal player; both must be denied.
4. Verify an authorized admin can access it only on the separate origin.
5. Inspect Android, Windows and Web game packages; no dashboard bundle or privileged secret may be present.
