# DARK NIGHT: SURVIVAL — Private Admin Dashboard

## Strict separation rule
This is an independent static web application. It is not part of the Godot game and must NEVER be linked or embedded in the player dashboard, game lobby, pause menu, settings, profile, inventory, maps, Android app, Windows build or Web game build. There is no in-game route, button, overlay, deep link or hint to this panel. Deploy it on a separate private URL/origin.

## Implemented in this repository
- Standalone responsive dark admin sign-in page.
- Supabase email/password authentication.
- Checks the signed-in user's `profiles.role` and only reveals the panel when role is exactly `admin`.
- Reads/writes non-secret JSON game settings in `public.game_admin_settings`.
- Appends and displays admin audit events in `public.admin_audit_logs`.
- SQL uses Row Level Security policies and a security-definer role-check function. Audit rows have no client update/delete policy.
- Browser app uses only the Supabase public anon/publishable key. Never use a service-role key or database password in the browser.

## Files
- `index.html`, `styles.css`, `app.js`: independent static dashboard.
- `supabase_admin_setup.sql`: schema, role-check function, grants and RLS policies.

## Setup (owner/admin only)
1. In the correct Supabase project, confirm `public.profiles` has `id uuid` and `role text`, and that the intended admin account's profile row has `role = 'admin'`. Do not promote ordinary players.
2. Run `supabase_admin_setup.sql` in Supabase SQL Editor. It creates the settings/audit tables and RLS policies. It does not create an admin user or change anyone's role.
3. Deploy ONLY this `admin-dashboard` folder to a separate static hosting site/origin (not the game site's public path). Do not configure this folder as the Godot game's web root.
4. Open the separate admin URL, enter the Supabase Project URL and public anon/publishable key, then sign in with the approved admin account.
5. Confirm a normal player account and a signed-out visitor are denied. Confirm an admin can create a harmless test setting and see its audit record. Delete the test setting afterwards.

## Important limitations / not yet released
- This is a first functional dashboard foundation, not a deployed production admin service. It has not yet been connected to a separate hosting origin or tested against the owner's live Supabase project.
- Dashboard setting values are non-secret JSON configuration only. Do not put provider API keys, passwords, access tokens, payment credentials or other secrets into this table. Secret provider management requires a server-side secret vault/Edge Function and additional review.
- The dashboard does not provide player account administration, live multiplayer controls, remote game deployment, or payments.
- Configure Supabase Auth redirect/site URL allow-lists for the separate dashboard origin before production use.
- Apply additional rate limits, MFA, admin session policy, backup/restore and audit monitoring before production release.
- A browser-side role check is only for presentation. Database RLS is the actual authorization boundary; never remove those policies.

## Release acceptance tests
1. Search all game scenes/scripts/player UI for dashboard/admin links and controls; expected: none.
2. Open main game, pause menu, co-op lobby, settings, profile, inventory and maps; expected: no dashboard reference.
3. Logged-out access and a normal-player account must be denied by Supabase RLS, not merely hidden by UI.
4. An approved admin can access the dashboard only on its separate origin.
5. Inspect Android, Windows and Web game packages; no dashboard bundle or privileged secret may be present.
6. Verify setting CRUD and audit logging on the actual Supabase project.
