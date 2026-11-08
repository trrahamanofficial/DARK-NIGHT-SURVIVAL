# Stage 4 — Settings and Offline Saves

## Implemented
- Settings continue to persist locally in `user://dark_night_settings.cfg`.
- Registered `SaveManager` as a Godot autoload; no account or internet connection is required.
- Three versioned offline save slots are supported by the save manager.
- Save data is written as JSON under `user://saves/`, written to a temporary file first, and the previous save is rotated to a backup before replacement.
- The current gameplay UI exposes Save Game and Load Game for Slot 1 from the pause/death overlay.
- Slot 1 captures player position and view direction, health, stamina, medkit count, flashlight state, monster position, and remaining medkit pickup positions.
- Loading restores the captured gameplay state and refreshes the HUD signals.

## Verification still required
- Android and Web export builds must pass on the exact Stage 4 revision.
- Save, close/relaunch, load, overwrite, and corrupted/incompatible save behavior must be exercised in a running game.
- Physical Android storage behavior must be verified on a real device.
- Slot 2 and Slot 3 are supported by the save manager API; the current in-game buttons intentionally expose Slot 1 only until a slot-selection UI is added.

## Safety and scope
- Saves are local to the device and are not cloud-synced.
- The save format includes a version number so incompatible future formats can be rejected safely.
- This stage does not claim real-device save QA until it is actually performed.
