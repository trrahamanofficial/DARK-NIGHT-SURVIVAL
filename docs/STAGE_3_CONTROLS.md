# Stage 3 — Player Controls

## Implemented in the current source
- Analog virtual joystick for mobile movement.
- Independent swipe camera look on the opposite side of the joystick.
- Mobile Run, Flashlight, and Heal controls.
- Touch-control size, opacity, side swapping, and camera sensitivity settings.
- New Arrange Touch Controls mode: enable it in Settings, drag the joystick/action buttons, then turn it off. Positions are saved locally as normalized screen coordinates.
- Responsive default control placement uses normalized viewport positions, so controls adapt to different screen sizes.
- PC key remapping for forward, back, left, right, run, and flashlight. Tap an action in Settings and press the replacement key; Escape cancels.
- Settings and custom key bindings persist locally in user://dark_night_settings.cfg.
- Existing desktop mouse-look, pause, health, stamina, and medkit actions remain.

## Verification still required
- Android and Web export workflows must pass against this exact source revision.
- Physical Android testing is still required for multi-touch, dragging, rotation, and small-screen comfort. The assistant cannot certify real-device behavior from export builds alone.
- PC keyboard remapping must be exercised in a running desktop build.
