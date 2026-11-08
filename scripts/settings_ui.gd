extends CanvasLayer

const CONFIG_PATH := "user://dark_night_settings.cfg"
var ui_scale := 1.0
var quality := "Auto"
var swapped := false
var touch_opacity := 0.8
var touch_sensitivity := 1.0
var panel: PanelContainer

func _ready() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CONFIG_PATH) == OK:
        ui_scale = float(cfg.get_value("controls", "scale", 1.0))
        quality = str(cfg.get_value("graphics", "quality", "Auto"))
        swapped = bool(cfg.get_value("controls", "swapped", false))
        touch_opacity = float(cfg.get_value("controls", "opacity", 0.8))
        touch_sensitivity = float(cfg.get_value("controls", "sensitivity", 1.0))
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

func _toggle_panel() -> void:
    if is_instance_valid(panel):
        panel.queue_free()
        panel = null
        return
    panel = PanelContainer.new()
    panel.name = "GameSettingsPanel"
    panel.position = Vector2(18, 128)
    panel.size = Vector2(340, 420)
    panel.z_index = 30
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)
    var title := Label.new()
    title.text = "GAME SETTINGS"
    box.add_child(title)
    var size_label := Label.new()
    size_label.text = "Touch button size"
    box.add_child(size_label)
    var slider := HSlider.new()
    slider.min_value = 0.7
    slider.max_value = 1.5
    slider.step = 0.1
    slider.value = ui_scale
    slider.value_changed.connect(_on_scale_changed)
    box.add_child(slider)
    var opacity_label := Label.new()
    opacity_label.text = "Touch button opacity"
    box.add_child(opacity_label)
    var opacity_slider := HSlider.new()
    opacity_slider.min_value = 0.25
    opacity_slider.max_value = 1.0
    opacity_slider.step = 0.05
    opacity_slider.value = touch_opacity
    opacity_slider.value_changed.connect(_on_opacity_changed)
    box.add_child(opacity_slider)
    var sensitivity_label := Label.new()
    sensitivity_label.text = "Camera look sensitivity"
    box.add_child(sensitivity_label)
    var sensitivity_slider := HSlider.new()
    sensitivity_slider.min_value = 0.5
    sensitivity_slider.max_value = 2.0
    sensitivity_slider.step = 0.1
    sensitivity_slider.value = touch_sensitivity
    sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    box.add_child(sensitivity_slider)
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
    var close_button := Button.new()
    close_button.text = "Close"
    close_button.pressed.connect(_toggle_panel)
    box.add_child(close_button)
    add_child(panel)

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
        control.size = base_size * ui_scale
        control.modulate.a = touch_opacity
        if control.name == "VirtualJoystick":
            control.set("radius", 66.0 * ui_scale)
            control.call("queue_redraw")
        if swapped:
            control.position = Vector2(viewport_size.x - base_pos.x - control.size.x, base_pos.y)
        else:
            control.position = base_pos
    var player := get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
    if player and player.has_method("set_touch_sensitivity_multiplier"):
        player.set_touch_sensitivity_multiplier(touch_sensitivity)
    if player and player.has_method("set_touch_look_on_right"):
        player.set_touch_look_on_right(not swapped)

func _apply_quality() -> void:
    var selected := quality
    if selected == "Auto":
        selected = "Low" if OS.has_feature("mobile") else "High"
    var scene := get_tree().current_scene
    if scene and scene.has_method("apply_graphics_quality"):
        scene.apply_graphics_quality(selected)

func _save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("controls", "scale", ui_scale)
    cfg.set_value("controls", "swapped", swapped)
    cfg.set_value("controls", "opacity", touch_opacity)
    cfg.set_value("controls", "sensitivity", touch_sensitivity)
    cfg.set_value("graphics", "quality", quality)
    cfg.save(CONFIG_PATH)
