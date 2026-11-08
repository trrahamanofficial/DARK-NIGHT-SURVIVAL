# DARK NIGHT: SURVIVAL — Confirmed Game Plan

## Player experience
- Horror survival game with first-person and third-person camera options.
- Realistic horror visual direction; scalable graphics presets for different hardware.
- Offline single-player is the first release priority. No login or signup required.
- Free to play. Ads disabled for the first two years; no paid features at launch.

## Selected game modes
1. Story Campaign
2. Survival Mode
3. Free Explore
4. Co-op Mode
5. Nightmare Mode
6. Custom Mode

## Selected maps
- Dark Forest
- Abandoned Hospital
- Old Village
- Underground Bunker
- Haunted School
- Abandoned Factory
- Underground Laboratory
- Snow Mountain
- Ghost Town

## Gameplay selections
- Survival, story missions, explore and escape
- Crafting and inventory
- Stealth and hiding
- Weapons and combat
- Intelligent monster AI, multiple monsters and boss encounters
- Difficulty: Easy, Normal, Hard, Nightmare
- Flashlight, battery, health and stamina, weapons, safe house, day/night, weather, achievements, food and water, first aid, character customization and vehicles

## Controls and platform behavior
- Android: on-screen touch controls, camera-look gesture, adjustable touch-button size, left/right control-side option.
- Windows PC: keyboard and mouse controls; touch buttons hidden.
- Controller support is planned as a later input pass and must be tested with actual controllers.
- Touch layout preferences are stored locally on the device.

## Graphics behavior
- Graphics menu: Auto, Low, Medium, High and Ultra presets.
- Auto selects a conservative preset on mobile and a higher preset on desktop.
- Players may change the preset manually; actual performance depends on device hardware.
- The current prototype quality presets adjust environment fog, lighting and shadows. They are not yet a full AAA graphics system.

## Platforms and release sequence
1. Android APK prototype and device testing.
2. Complete Android gameplay and performance pass.
3. Windows PC export and keyboard/mouse/controller testing.
4. Web export with reduced effects where necessary.

## Multiplayer and backend
- Co-op mode is a planned feature, not yet implemented in the current prototype.
- Supabase can store accounts/data/settings, but it is not a replacement for an authoritative real-time multiplayer game server.
- Add a dedicated multiplayer server before enabling online co-op.
- Keep privileged admin credentials out of the game client. A private admin dashboard must be protected separately.

## Honest development status
The repository currently contains an early procedural forest prototype, basic movement, flashlight, a simple monster, mobile touch controls, and initial graphics/control settings. The full map list, story, inventory, missions, advanced monsters, vehicles, co-op, saves and release hardening still require implementation and testing. Do not describe the game as complete or Play Store-ready until builds and real-device QA pass.
