extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const MONSTER_SCRIPT = preload("res://scripts/monster.gd")

func _ready() -> void:
    _setup_environment()
    _make_ground()
    _make_forest()
    _spawn_player()
    _spawn_monster()
    _make_hud()

func _setup_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.055, 0.075, 0.095)
    env.ambient_light_energy = 0.22
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.025, 0.035, 0.045)
    env.fog_density = 0.035
    var world_env := WorldEnvironment.new()
    world_env.environment = env
    add_child(world_env)
    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-48, -28, 0)
    moon.light_color = Color(0.38, 0.48, 0.62)
    moon.light_energy = 0.16
    moon.shadow_enabled = true
    add_child(moon)

func _make_ground() -> void:
    var body := StaticBody3D.new()
    body.name = "ForestFloor"
    var mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(100, 100)
    mesh.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.035, 0.052, 0.038)
    mat.roughness = 1.0
    mesh.material_override = mat
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100, 0.5, 100)
    collision.shape = shape
    collision.position.y = -0.25
    body.add_child(collision)
    add_child(body)

func _make_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261108
    for i in range(85):
        var x := rng.randf_range(-42, 42)
        var z := rng.randf_range(-42, 42)
        if Vector2(x, z).length() < 5.5:
            continue
        _make_tree(Vector3(x, 0, z), rng.randf_range(0.75, 1.5))

func _make_tree(pos: Vector3, scale_factor: float) -> void:
    var tree := StaticBody3D.new()
    tree.position = pos
    var trunk := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.22 * scale_factor
    cylinder.bottom_radius = 0.38 * scale_factor
    cylinder.height = 4.5 * scale_factor
    trunk.mesh = cylinder
    trunk.position.y = cylinder.height * 0.5
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.075, 0.055, 0.04)
    bark.roughness = 1.0
    trunk.material_override = bark
    tree.add_child(trunk)
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.65 * scale_factor
    sphere.height = 3.0 * scale_factor
    crown.mesh = sphere
    crown.position.y = 4.1 * scale_factor
    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.018, 0.045, 0.027)
    leaves.roughness = 1.0
    crown.material_override = leaves
    tree.add_child(crown)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38 * scale_factor
    shape.height = 4.5 * scale_factor
    collision.shape = shape
    collision.position.y = 2.25 * scale_factor
    tree.add_child(collision)
    add_child(tree)

func _spawn_player() -> void:
    var player := CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0.15, 0)
    var capsule := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.8
    capsule.shape = shape
    capsule.position.y = 0.9
    player.add_child(capsule)
    var head := Node3D.new()
    head.name = "Head"
    head.position.y = 1.55
    player.add_child(head)
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 78
    head.add_child(camera)
    var light := SpotLight3D.new()
    light.name = "Flashlight"
    light.position = Vector3(0, -0.08, -0.18)
    light.light_color = Color(0.78, 0.86, 1.0)
    light.light_energy = 4.2
    light.spot_range = 23
    light.spot_angle = 34
    light.shadow_enabled = true
    camera.add_child(light)
    add_child(player)

func _spawn_monster() -> void:
    var monster := CharacterBody3D.new()
    monster.name = "Wanderer"
    monster.set_script(MONSTER_SCRIPT)
    monster.position = Vector3(0, 0.1, -17)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 2.3
    body.mesh = capsule
    body.position.y = 1.15
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.012, 0.016, 0.018)
    mat.roughness = 1.0
    body.material_override = mat
    monster.add_child(body)
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.48
    shape.height = 2.3
    col.shape = shape
    col.position.y = 1.15
    monster.add_child(col)
    add_child(monster)

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    var label := Label.new()
    label.text = "DARK NIGHT  •  SURVIVE\nWASD: Move   SHIFT: Run   F: Flashlight   ESC: Mouse"
    label.position = Vector2(20, 18)
    label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.88, 0.85))
    label.add_theme_font_size_override("font_size", 16)
    layer.add_child(label)
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-5, -12)
    crosshair.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.7))
    layer.add_child(crosshair)
    add_child(layer)
    if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
        _make_mobile_controls(layer)

func _make_mobile_controls(layer: CanvasLayer) -> void:
    var screen := get_viewport().get_visible_rect().size
    var button_size := Vector2(64, 64)
    var left_x := 24.0
    var bottom_y := screen.y - 94.0
    _add_hold_button(layer, "↑", "move_forward", Vector2(left_x + 70, bottom_y - 70), button_size)
    _add_hold_button(layer, "↓", "move_back", Vector2(left_x + 70, bottom_y + 2), button_size)
    _add_hold_button(layer, "←", "move_left", Vector2(left_x, bottom_y + 2), button_size)
    _add_hold_button(layer, "→", "move_right", Vector2(left_x + 140, bottom_y + 2), button_size)
    _add_hold_button(layer, "RUN", "run", Vector2(screen.x - 166, bottom_y - 4), Vector2(70, 58))
    var light_button := Button.new()
    light_button.text = "LIGHT"
    light_button.position = Vector2(screen.x - 88, bottom_y - 4)
    light_button.size = Vector2(76, 58)
    light_button.focus_mode = Control.FOCUS_NONE
    light_button.add_theme_font_size_override("font_size", 14)
    light_button.pressed.connect(_toggle_player_flashlight)
    layer.add_child(light_button)

func _add_hold_button(layer: CanvasLayer, caption: String, action: StringName, pos: Vector2, button_size: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = button_size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)
    button.button_down.connect(_press_action.bind(action))
    button.button_up.connect(_release_action.bind(action))
    layer.add_child(button)

func _press_action(action: StringName) -> void:
    Input.action_press(action)

func _release_action(action: StringName) -> void:
    Input.action_release(action)

func _toggle_player_flashlight() -> void:
    var player := get_node_or_null("Player")
    if player != null and player.has_method("_toggle_flashlight"):
        player._toggle_flashlight()
