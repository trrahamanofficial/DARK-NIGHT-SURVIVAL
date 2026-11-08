# Stage 11 — PC and Web Support

## Implemented feature pass
- Existing desktop WASD movement, Shift sprint, mouse-look, Escape pause and F flashlight controls are retained.
- Existing Settings screen includes persistent keyboard remapping for movement, sprint and flashlight actions, plus a saved desktop mouse-sensitivity slider.
- Auto graphics now selects Low on mobile, Medium on Web and High on desktop.
- Existing graphics presets support Auto, Low, Medium, High and Ultra; Auto selects Low on mobile and High on desktop.
- Touch controls are created only when the platform reports mobile/touch input; desktop builds use keyboard and mouse.
- Web export remains available through the existing Web preset and CI workflow.
- Added a Windows Desktop x86_64 export preset.
- Added a Windows PC CI workflow that exports the EXE and PCK together and uploads a ZIP artifact.

## Build verification
The Windows workflow must pass on the same source commit as the Android and Web workflows before Stage 11 export verification is considered complete. Export success proves packaging only; it does not replace Windows runtime testing.

## Remaining QA
- Verify keyboard/mouse play in a Windows desktop runtime.
- Verify browser focus, mouse capture and keyboard input in Web browsers.
- Check UI scaling at 720p, 1080p, ultrawide and narrow browser windows.
- Test graphics presets on representative PC hardware.
- Gamepad support is not advertised or included until tested.
