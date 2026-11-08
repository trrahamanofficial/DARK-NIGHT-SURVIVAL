# DARK NIGHT: SURVIVAL — Master Delivery Plan

## Delivery promise and limits
This repository is being developed in staged increments. A successful Android export proves that an APK was packaged; it does not prove that every gameplay feature is complete or device-tested. No final APK is declared ready until the release checklist is passed.

## Product decisions
- Platforms: Android, Windows PC, and Web (separate builds and QA).
- Offline single-player must work without an account or internet connection.
- Online co-op is planned for 1–4 players and requires a dedicated authoritative multiplayer service; it is not provided by a static web host or a basic database alone.
- Game modes: Story Campaign, Survival Mode, Free Explore, Co-op Mode, Nightmare Mode, Custom Mode.
- Difficulty: Easy, Normal, Hard, Nightmare, Dynamic Difficulty.
- Android defaults to a performance-oriented graphics profile; Windows defaults to a higher-quality profile. Players can change supported settings.
- Mobile controls must support resizing, repositioning, opacity and side swapping. PC controls must support keyboard/mouse and later gamepad/key rebinding.
- The Admin Dashboard is a separate protected application. No admin password, service-role key, or privileged secret may be shipped in the game client.
- No player login is required for offline play. Ads and paid upgrades remain disabled for the initial release.

## 10–15 staged implementation plan
1. **Foundation:** project configuration, game-mode/difficulty/platform settings schemas, repository layout and build baseline.
2. **Core gameplay loop:** player state, health, stamina, damage, death/restart and pause flow.
3. **Player controls:** mobile joystick/look/action controls, customization and PC keyboard/mouse controls.
4. **Settings and saves:** persistent settings, offline save slots and safe versioned save data.
5. **Survival systems:** inventory, pickups, crafting and resource management.
6. **World and atmosphere:** forest polish, collision/navigation, lighting, ambience and audio.
7. **Enemy systems:** detection, chase, attack, damage, retreat and multiple monster archetypes.
8. **Story Campaign:** mission objectives, progression, escape sequence and checkpoints.
9. **Additional maps:** Abandoned Hospital, Old Village and Underground Bunker.
10. **Game modes and difficulty:** wire all six modes and difficulty profiles into playable flows.
11. **PC and Web support:** desktop input, scalable UI, graphics presets and separate exports.
12. **Co-op foundation:** authoritative server architecture, 1–4 player sessions, reconnect and security review.
13. **Separate Admin Dashboard:** protected login, role checks, game content/settings management and audit log.
14. **QA and optimization:** Android device tests, PC/Web tests, offline tests, performance and crash fixes.
15. **Release packaging:** signed release APK process, Windows/Web packages, documentation and final verification.

## Current stage status (2026-11-08)
- Stage 1: foundation and export baseline implemented; export builds passed.
- Stage 2: core gameplay loop implemented; Android/Web export builds passed; runtime gameplay QA remains.
- Stage 3: mobile and desktop controls implemented; Android/Web export builds passed; Android device QA remains. PC device QA is not required for this mobile-only owner workflow and remains a later platform QA item.
- Stage 4: local settings persistence and versioned offline save/load implemented; Android/Web export verification and real-device save/reload QA remain.
- Stage 5: initial survival loop implemented (resource pickups, inventory, crafting, food/water stamina recovery, save persistence); export verification and runtime gameplay QA remain.
- Stage 6: forest environment pass implemented (procedural terrain details, night fog and moonlight, visible cleared trail corridor, and generated offline wind/night-insect ambience). Android/Web export builds passed on the Stage 6 final code; a full navigation mesh, real-device audio/performance tuning and runtime QA remain.

## Release checklist
- [ ] All six modes are playable or explicitly marked unavailable in the UI.
- [ ] Difficulty selection changes actual gameplay.
- [ ] Android touch controls work and can be customized.
- [ ] PC keyboard/mouse controls work; gamepad support is tested if included.
- [ ] Android and PC graphics presets are tested on real target devices.
- [ ] Offline save/load and restart are reliable.
- [ ] No privileged dashboard credentials or server secrets are present in client builds.
- [ ] Admin Dashboard is separately deployed and access-protected.
- [ ] Web, Android and Windows builds are independently tested.
- [ ] Multiplayer is tested against a deployed authoritative server before being advertised as available.
- [ ] Final APK installs and launches on a real Android device.

## Current baseline
The current playable content is an early procedural Dark Forest prototype. Existing settings UI and touch controls are an early implementation, not final QA-approved systems. Configuration files added in Stage 1 are design data until connected to gameplay code in later stages.

- Stage 7: first enemy AI pass implemented (patrol/investigate/chase/attack/retreat states, line-of-sight and sprint-noise detection, attack wind-up/cooldown, enemy health/death API, Wanderer, Stalker and Brute archetypes, and save persistence for enemy positions). Player weapons/hit detection, navigation/obstacle avoidance, animations/audio and runtime QA remain.
- Stage 8: first offline story campaign pass implemented (four sequential chapters, in-world objective markers, three evidence pickups, story HUD/text beats, mission progression, save persistence and death checkpoints). Cinematic cutscenes/voice acting and runtime QA remain.
- Stage 9: first additional-map pass implemented with selectable Dark Forest, Abandoned Hospital, Old Village and Underground Bunker locations. The three added maps use distinct procedural layouts, structures and lighting. Dedicated map-specific missions, richer art/props, navigation tuning and runtime QA remain.
- Stage 10: feature implementation pass completed. Story objectives are restricted to Story Campaign; Survival adds timed escalating waves with a live countdown HUD; Free Explore disables enemies/objectives; Nightmare adds threats and tuning; difficulty profiles are applied to spawned enemies and resource pickups; Dynamic difficulty uses player health when enemies spawn; Custom Mode has persistent enemy-threat and resource-amount sliders. Co-op is explicitly Coming Soon and not enabled. Android and Web CI exports passed on commit `02e79a96fc5f644fb806e2f21b0cac0d0a764637`; physical runtime balancing remains.
- Stage 11: first PC/Web support pass implemented. Existing keyboard/mouse controls, key remapping, saved desktop mouse sensitivity, platform-aware Auto graphics (Low mobile / Medium Web / High desktop), and touch-only mobile controls are connected; Windows Desktop x86_64 export preset and CI workflow added. Windows, Android and Web CI verification on the final Stage 11 source and desktop/browser runtime QA remain.
