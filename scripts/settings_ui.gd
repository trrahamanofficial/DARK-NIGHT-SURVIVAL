extends CanvasLayer

const CONFIG_PATH := "user://dark_night_settings.cfg"
const TOUCH_ACTIONS := ["move_forward", "move_back", "move_left", "move_right", "run", "flashlight"]
const ACTION_LABELS := ["Move Forward", "Move Back", "Move Left", "Move Right", "Run", "Flashlight"]

var ui_scale := 1.0
var quality := "Auto"
var swapped := false
var touch_opacity := 0.8
var touch_sensitivity := 1.0
var mouse_sensitivity := 1.0
var panel: PanelContainer
var arrange_mode := false
var dragging_control: Control
var drag_touch_index := -1
var drag_offset := Vector2.ZERO
var key_capture_action := ""
var key_capture_button: Button
var key_buttons: Dictionary = {}
var saved_layout: Dictionary = {}

func _ready() -> void:
    _load_settings()
    var open_button := Button.new()
    open_button.name = "SettingsButton"
    open_button.text = "⚙"
    open_button.position = Vector2(18, 72)
    open_button.size = Vector2(58, 48)
    open_button.z_index = 20
    open_button.pressed.connect(_toggle_panel)
    add_child(open_button)
    call_deferred("_apply_control_settings")
    _apply_quality()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        call_deferred("_apply_control_settings")

func _input(event: InputEvent) -> void:
    if not arrange_mode:
        return
    if event is InputEventScreenTouch:
        if event.pressed and dragging_control == null:
            _begin_control_drag(event.position, event.index)
        elif not event.pressed and event.index == drag_touch_index:
            _finish_control_drag()
    elif event is InputEventScreenDrag and event.index == drag_touch_index and dragging_control != null:
        _move_dragged_control(event.position)
        get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if key_capture_action == "" or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        key_capture_action = ""
        if is_instance_valid(key_capture_button):
            key_capture_button.text = "Cancelled"
        return
    var action := key_capture_action
    key_capture_action = ""
    _set_action_key(action, event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
    _save_settings()
    _refresh_key_button(action)
    get_viewport().set_input_as_handled()

func _load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CONFIG_PATH) != OK:
        return
    ui_scale = float(cfg.get_value("controls", "scale", 1.0))
    quality = str(cfg.get_value("graphics", "quality", "Auto"))
    swapped = bool(cfg.get_value("controls", "swapped", false))
    touch_opacity = float(cfg.get_value("controls", "opacity", 0.8))
    touch_sensitivity = float(cfg.get_value("controls", "sensitivity", 1.0))
    mouse_sensitivity = float(cfg.get_value("controls", "mouse_sensitivity", 1.0))
    saved_layout = cfg.get_value("controls", "layout", {})
    for action in TOUCH_ACTIONS:
        var key_code := int(cfg.get_value("keys", action, -1))
        if key_code >= 0:
            _set_action_key(action, key_code)

func _toggle_panel() -> void:
    if is_instance_valid(panel):
        panel.queue_free()
        panel = null
        return
    panel = PanelContainer.new()
    panel.name = "GameSettingsPanel"
    panel.position = Vector2(18, 128)
    panel.size = Vector2(350, 560)
    panel.z_index = 30
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(330, 520)
    panel.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 9)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(box)
    var title := Label.new()
    title.text = "GAME SETTINGS"
    box.add_child(title)

    _add_slider(box, "Touch control size", 0.7, 1.5, 0.1, ui_scale, _on_scale_changed)
    _add_slider(box, "Touch control opacity", 0.25, 1.0, 0.05, touch_opacity, _on_opacity_changed)
    _add_slider(box, "Camera look sensitivity", 0.5, 2.0, 0.1, touch_sensitivity, _on_sensitivity_changed)
    if not OS.has_feature("mobile"):
        _add_slider(box, "PC mouse sensitivity", 0.5, 2.0, 0.1, mouse_sensitivity, _on_mouse_sensitivity_changed)

    var quality_label := Label.new()
    quality_label.text = "Graphics quality"
    box.add_child(quality_label)
    var quality_picker := OptionButton.new()
    for option in ["Auto", "Low", "Medium", "High", "Ultra"]:
        quality_picker.add_item(option)
    quality_picker.select(maxi(0, ["Auto", "Low", "Medium", "High", "Ultra"].find(quality)))
    quality_picker.item_selected.connect(_on_quality_selected)
    box.add_child(quality_picker)

    var swap_button := Button.new()
    swap_button.text = "Swap touch-control sides: " + ("ON" if swapped else "OFF")
    swap_button.pressed.connect(_toggle_sides.bind(swap_button))
    box.add_child(swap_button)

    var arrange_button := Button.new()
    arrange_button.text = "Arrange touch controls: " + ("ON" if arrange_mode else "OFF")
    arrange_button.pressed.connect(_toggle_arrange.bind(arrange_button))
    box.add_child(arrange_button)
    var arrange_help := Label.new()
    arrange_help.text = "When ON, drag the joystick and action buttons to move them. Turn OFF when finished."
    arrange_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(arrange_help)

    var keys_title := Label.new()
    keys_title.text = "PC KEYBOARD — TAP A KEY BUTTON, THEN PRESS A NEW KEY"
    keys_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(keys_title)
    for i in range(TOUCH_ACTIONS.size()):
        var action: String = TOUCH_ACTIONS[i]
        var key_button := Button.new()
        key_button.name = "Key_" + action
        key_button.pressed.connect(_start_key_capture.bind(action))
        key_buttons[action] = key_button
        box.add_child(key_button)
        _refresh_key_button(action)

    var close_button := Button.new()
    close_button.text = "Close"
    close_button.pressed.connect(_toggle_panel)
    box.add_child(close_button)
    add_child(panel)

func _add_slider(parent: VBoxContainer, caption: String, minimum: float, maximum: float, step: float, current: float, callback: Callable) -> void:
    var label := Label.new()
    label.text = caption
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = step
    slider.value = current
    slider.value_changed.connect(callback)
    parent.add_child(slider)

func _toggle_arrange(button: Button) -> void:
    arrange_mode = not arrange_mode
    button.text = "Arrange touch controls: " + ("ON" if arrange_mode else "OFF")
    if not arrange_mode:
        _finish_control_drag()

func _begin_control_drag(point: Vector2, touch_index: int) -> void:
    var controls := get_tree().get_nodes_in_group("touch_controls")
    for i in range(controls.size() - 1, -1, -1):
        var control := controls[i] as Control
        if control.visible and Rect2(control.position, control.size).has_point(point):
            dragging_control = control
            drag_touch_index = touch_index
            drag_offset = point - control.position
            get_viewport().set_input_as_handled()
            return

func _move_dragged_control(point: Vector2) -> void:
    if not is_instance_valid(dragging_control):
        _finish_control_drag()
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var new_pos := point - drag_offset
    new_pos.x = clampf(new_pos.x, 0.0, maxf(0.0, viewport_size.x - dragging_control.size.x))
    new_pos.y = clampf(new_pos.y, 0.0, maxf(0.0, viewport_size.y - dragging_control.size.y))
    dragging_control.position = new_pos

func _finish_control_drag() -> void:
    if is_instance_valid(dragging_control):
        var viewport_size := get_viewport().get_visible_rect().size
        saved_layout[dragging_control.name] = Vector2(
            dragging_control.position.x / maxf(1.0, viewport_size.x),
            dragging_control.position.y / maxf(1.0, viewport_size.y)
        )
        _save_settings()
    dragging_control = null
    drag_touch_index = -1

func _on_scale_changed(value: float) -> void:
    ui_scale = value
    _save_settings()
    _apply_control_settings()

func _on_opacity_changed(value: float) -> void:
    touch_opacity = value
    _save_settings()
    _apply_control_settings()

func _on_sensitivity_changed(value: float) -> void:
    touch_sensitivity = value
    _save_settings()
    _apply_control_settings()

func _on_mouse_sensitivity_changed(value: float) -> void:
    mouse_sensitivity = value
    _save_settings()
    _apply_control_settings()

func _on_quality_selected(index: int) -> void:
    quality = ["Auto", "Low", "Medium", "High", "Ultra"][index]
    _save_settings()
    _apply_quality()

func _toggle_sides(button: Button) -> void:
    swapped = not swapped
    button.text = "Swap touch-control sides: " + ("ON" if swapped else "OFF")
    _save_settings()
    _apply_control_settings()

func _apply_control_settings() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    for control in get_tree().get_nodes_in_group("touch_controls"):
        var base_size: Vector2 = control.get_meta("base_size", control.size)
        var base_pos: Vector2 = control.get_meta("base_pos", control.position)
        var base_ratio: Vector2 = control.get_meta("base_ratio", Vector2(base_pos.x / maxf(1.0, viewport_size.x), base_pos.y / maxf(1.0, viewport_size.y)))
        control.size = base_size * ui_scale
        control.modulate.a = touch_opacity
        if control.name == "VirtualJoystick":
            control.custom_minimum_size = base_size * ui_scale
            control.set("radius", 66.0 * ui_scale)
            control.call("queue_redraw")
        var default_pos := Vector2(base_ratio.x * viewport_size.x, base_ratio.y * viewport_size.y)
        if swapped:
            default_pos.x = viewport_size.x - default_pos.x - control.size.x
        var ratio: Vector2 = saved_layout.get(control.name, Vector2(-1, -1))
        control.position = Vector2(ratio.x * viewport_size.x, ratio.y * viewport_size.y) if ratio.x >= 0.0 else default_pos
    var player := get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
    if player and player.has_method("set_touch_sensitivity_multiplier"):
        player.set_touch_sensitivity_multiplier(touch_sensitivity)
    if player and player.has_method("set_touch_look_on_right"):
        player.set_touch_look_on_right(not swapped)
    if player and player.has_method("set_mouse_sensitivity_multiplier"):
        player.set_mouse_sensitivity_multiplier(mouse_sensitivity)

func _apply_quality() -> void:
    var selected := quality
    if selected == "Auto":
        selected = "Low" if OS.has_feature("mobile") else ("Medium" if OS.has_feature("web") else "High")
    var scene := get_tree().current_scene
    if scene and scene.has_method("apply_graphics_quality"):
        scene.apply_graphics_quality(selected)

func _set_action_key(action: String, key_code: int) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    InputMap.action_erase_events(action)
    var key_event := InputEventKey.new()
    key_event.physical_keycode = key_code
    InputMap.action_add_event(action, key_event)

func _start_key_capture(action: String) -> void:
    key_capture_action = action
    _refresh_key_button(action)
    if is_instance_valid(key_buttons.get(action)):
        key_buttons[action].text = "Press a key (Esc cancels)..."

func _refresh_key_button(action: String) -> void:
    if not key_buttons.has(action) or not is_instance_valid(key_buttons[action]):
        return
    var key_name := "Unassigned"
    var events := InputMap.action_get_events(action)
    for input_event in events:
        if input_event is InputEventKey:
            key_name = OS.get_keycode_string(input_event.physical_keycode if input_event.physical_keycode != KEY_NONE else input_event.keycode)
            break
    var label_index := TOUCH_ACTIONS.find(action)
    key_buttons[action].text = ACTION_LABELS[label_index] + ": " + key_name

func _save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("controls", "scale", ui_scale)
    cfg.set_value("controls", "swapped", swapped)
    cfg.set_value("controls", "opacity", touch_opacity)
    cfg.set_value("controls", "sensitivity", touch_sensitivity)
    cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
    cfg.set_value("controls", "layout", saved_layout)
    cfg.set_value("graphics", "quality", quality)
    for action in TOUCH_ACTIONS:
        var key_code := -1
        for input_event in InputMap.action_get_events(action):
            if input_event is InputEventKey:
                key_code = input_event.physical_keycode if input_event.physical_keycode != KEY_NONE else input_event.keycode
                break
        cfg.set_value("keys", action, key_code)
    cfg.save(CONFIG_PATH)
