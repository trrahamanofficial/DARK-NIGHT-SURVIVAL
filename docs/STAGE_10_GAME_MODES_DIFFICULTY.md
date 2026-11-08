# Stage 10 — Game Modes and Difficulty

## Implemented
- Persistent offline mode and difficulty selection from the pause menu.
- Story Campaign: story objectives and campaign HUD are active only in Story Campaign.
- Survival Mode: timed escalating enemy waves with a live countdown HUD and increasing spawn pressure.
- Free Explore: disables enemy spawning and story objective triggers.
- Nightmare Mode: adds extra threats and increases enemy health, damage and detection.
- Custom Mode: saved Enemy Threat (0.5x–2.0x) and Resource Amount (0.5x–2.0x) sliders.
- Easy, Normal, Hard and Nightmare profiles tune enemy damage, health, detection and resource pickup amounts.
- Dynamic difficulty uses the player's health when enemies spawn to set enemy damage.
- Enemy archetype stats receive the selected mode/difficulty tuning at spawn.
- Co-op is clearly marked Coming Soon and cannot be selected as playable; no multiplayer server is claimed.

## Not included in Stage 10
- Online co-op implementation; this remains Stage 12 and requires a dedicated authoritative server.
- Mode-specific victory/defeat rules and unique objectives for every map.
- Final difficulty balancing, survival pacing playtests and physical Android runtime QA.

## Verification status
- Android and Web CI export builds must pass on the final Stage 10 commit.
- CI export success confirms packaging only; it does not replace on-device gameplay testing.
