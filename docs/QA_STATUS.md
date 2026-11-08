# DARK NIGHT: SURVIVAL — QA status (2026-11-08)

## Automated export verification
Latest code-changing co-op client commit: `5f97d810b68d032380275f62630fb69f0409d0ec`.
- Android APK workflow #75 — SUCCESS: https://github.com/trrahamanofficial/DARK-NIGHT-SURVIVAL/actions/runs/42459743516
- Windows PC workflow #9 — SUCCESS: https://github.com/trrahamanofficial/DARK-NIGHT-SURVIVAL/actions/runs/42459743481
- Web workflow #10 — SUCCESS: https://github.com/trrahamanofficial/DARK-NIGHT-SURVIVAL/actions/runs/42459743759

Earlier Stage 12 integrated lobby commit `88480a80d844178e086431a091b814b008f38b5b` also passed Android #74, Windows #8 and Web #9.

These results prove the project exported successfully. They do not prove gameplay works on physical devices or that Nakama transport works against a deployed server.

## Static checks performed
- Inspected `project.godot`: no Admin Dashboard autoload, route or UI registration.
- Inspected `scripts/world.gd`: pause menu adds only the Co-op Multiplayer button; co-op panel contains connect/create/join/disconnect/back controls only. No Admin/Personal Dashboard button or link.
- Inspected `scripts/player.gd`: mobile movement vector exists and is the source read by the co-op input sender.
- Added `admin-dashboard/.gdignore` so Godot ignores the independent web application directory.
- Corrected Nakama device authentication to pass the API key as the `http_key` query parameter.
- Added SQL RLS policies for dashboard settings and append-only audit logs.

## Must still be tested on real targets
- Android install/launch, touch controls, orientation, save/load, audio, frame rate, crash-free gameplay and all maps/modes.
- Windows executable launch, keyboard/mouse controls, resolution and performance.
- Browser runtime and responsive controls.
- Nakama deployment, TLS, device authentication, RPC, join/full-match rejection, 2–4 clients, packet loss, disconnect/reconnect and authoritative state.
- Supabase dashboard against the owner's actual project: run SQL, verify admin role, test logged-out and normal-player denial, admin settings CRUD and audit log.
- Confirm the separately deployed admin origin is not linked from any game UI.

## Release decision
**Not release-ready yet.** No physical Android/Windows device QA has been performed in this workflow, no public Nakama server is deployed, and the private dashboard has not been deployed to a separate origin or tested against the owner's Supabase project. Keep co-op marked Coming Soon. Do not label the current APK as final release.
