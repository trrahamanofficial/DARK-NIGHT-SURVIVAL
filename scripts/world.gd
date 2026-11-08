extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const MONSTER_SCRIPT = preload("res://scripts/monster.gd")

var health_bar: ProgressBar
var stamina_bar: ProgressBar
var status_label: Label
var medkit_count_label: Label
var resources_label: Label
var story_label: Label
var overlay_layer: CanvasLayer
var is_game_over := false
var survival_wave := 1
var survival_wave_timer := 35.0
var survival_wave_label: Label
var mode_status_label: Label

func _ready() -> void:
    _setup_environment()
    _make_ground()
    match MapManager.current_map_id:
        "hospital":
            _make_hospital_map()
        "village":
            _make_village_map()
        "bunker":
            _make_bunker_map()
        _:
            _start_forest_ambience()
            _make_forest()
            _make_forest_details()
    _spawn_player()
    _spawn_mode_enemies()
    _spawn_medkit(Vector3(5.0, 0.0, -7.0))
    _spawn_medkit(Vector3(-8.0, 0.0, -15.0))
    _spawn_resource_pickup(Vector3(8.0, 0.0, -11.0), "cloth", ModeManager.scale_resource_amount(2))
    _spawn_resource_pickup(Vector3(-11.0, 0.0, -8.0), "herb", ModeManager.scale_resource_amount(2))
    _spawn_resource_pickup(Vector3(13.0, 0.0, -19.0), "scrap", ModeManager.scale_resource_amount(2))
    _spawn_resource_pickup(Vector3(-16.0, 0.0, -21.0), "food", ModeManager.scale_resource_amount(1))
    _spawn_resource_pickup(Vector3(18.0, 0.0, -5.0), "water", ModeManager.scale_resource_amount(1))
    if ModeManager.current_mode == "story_campaign":
        StoryCampaign.begin_if_new()
        if MapManager.current_map_id == "forest":
            _make_story_objectives()
    _make_hud()

func _process(delta: float) -> void:
    if get_tree().paused or is_game_over:
        return
    if ModeManager.current_mode == "survival":
        survival_wave_timer -= delta
        if survival_wave_timer <= 0.0:
            survival_wave += 1
            survival_wave_timer = maxf(14.0, 35.0 - float(survival_wave) * 1.5)
            _spawn_survival_wave()

func _spawn_mode_enemies() -> void:
    if ModeManager.current_mode == "free_explore":
        return
    _spawn_monster()
    if ModeManager.current_mode == "nightmare":
        _spawn_monster("Stalker", Vector3(19.0, 0.1, -23.0), "stalker")
        _spawn_monster("Brute", Vector3(-20.0, 0.1, -23.0), "brute")
        _spawn_monster("Stalker_2", Vector3(-18.0, 0.1, 18.0), "stalker")
    elif ModeManager.current_mode == "survival":
        _spawn_monster("Stalker", Vector3(19.0, 0.1, -23.0), "stalker")
    else:
        _spawn_monster("Stalker", Vector3(19.0, 0.1, -23.0), "stalker")
        _spawn_monster("Brute", Vector3(-20.0, 0.1, -23.0), "brute")

func _spawn_survival_wave() -> void:
    var player := get_node_or_null("Player")
    if player == null or player.is_dead:
        return
    var archetype := "stalker" if survival_wave % 3 == 0 else ("brute" if survival_wave % 3 == 2 else "wanderer")
    var spawn_pos := player.global_position + Vector3(18.0, 0.1, 16.0)
    var enemy_name := "Wave_%d_Enemy_%d" % [survival_wave, get_tree().get_nodes_in_group("enemies").size() + 1]
    _spawn_monster(enemy_name, spawn_pos, archetype)
    if survival_wave_label != null:
        survival_wave_label.text = "SURVIVAL WAVE %d  |  NEXT THREAT IN %ds" % [survival_wave, roundi(survival_wave_timer)]

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        toggle_pause()
        get_viewport().set_input_as_handled()

func toggle_pause() -> void:
    if is_game_over:
        return
    if get_tree().paused:
        _close_overlay()
    else:
        _show_overlay("PAUSED", "The forest is waiting. Take a breath.", true)
        get_tree().paused = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_overlay() -> void:
    get_tree().paused = false
    if overlay_layer != null:
        overlay_layer.queue_free()
        overlay_layer = null
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_health_changed(current: float, maximum: float) -> void:
    if health_bar != null:
        health_bar.max_value = maximum
        health_bar.value = current
    if status_label != null:
        status_label.text = "HEALTH  %d / %d" % [roundi(current), roundi(maximum)]

func _on_stamina_changed(current: float, maximum: float) -> void:
    if stamina_bar != null:
        stamina_bar.max_value = maximum
        stamina_bar.value = current

func _on_inventory_changed(medkit_count: int) -> void:
    if medkit_count_label != null:
        medkit_count_label.text = "MEDKIT  x%d  |  H / HEAL" % medkit_count

func _on_resources_changed(resources: Dictionary) -> void:
    if resources_label != null:
        resources_label.text = "CLOTH %d  HERB %d  SCRAP %d  FOOD %d  WATER %d" % [
            int(resources.get("cloth", 0)), int(resources.get("herb", 0)),
            int(resources.get("scrap", 0)), int(resources.get("food", 0)),
            int(resources.get("water", 0))
        ]

func _on_resource_body_entered(body: Node3D, pickup: Area3D, item: String, amount: int) -> void:
    if body.name != "Player" or not body.has_method("add_resource"):
        return
    body.add_resource(item, amount)
    pickup.queue_free()

func _spawn_resource_pickup(position_3d: Vector3, item: String, amount: int) -> void:
    var pickup := Area3D.new()
    pickup.name = "Pickup_" + item.capitalize()
    pickup.add_to_group("save_resource_pickups")
    pickup.position = position_3d + Vector3(0.0, 0.55, 0.0)
    pickup.set_meta("item", item)
    pickup.set_meta("amount", amount)
    var colors := {
        "cloth": Color(0.55, 0.62, 0.72), "herb": Color(0.18, 0.62, 0.24),
        "scrap": Color(0.55, 0.48, 0.38), "food": Color(0.78, 0.48, 0.16),
        "water": Color(0.12, 0.48, 0.82)
    }
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.55, 0.42, 0.55)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = colors.get(item, Color.WHITE)
    material.roughness = 0.8
    mesh.material_override = material
    pickup.add_child(mesh)
    var label := Label3D.new()
    label.text = item.to_upper() + " +" + str(amount)
    label.font_size = 32
    label.pixel_size = 0.006
    label.position.y = 0.45
    pickup.add_child(label)
    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 1.2
    collision.shape = sphere
    pickup.add_child(collision)
    pickup.body_entered.connect(_on_resource_body_entered.bind(pickup, item, amount))
    add_child(pickup)

func _on_medkit_body_entered(body: Node3D, pickup: Area3D) -> void:
    if body.name != "Player" or not body.has_method("add_medkit"):
        return
    body.add_medkit(1)
    pickup.queue_free()

func _spawn_medkit(position_3d: Vector3) -> void:
    var pickup := Area3D.new()
    pickup.name = "MedkitPickup"
    pickup.add_to_group("save_pickups")
    pickup.position = position_3d + Vector3(0.0, 0.55, 0.0)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.65, 0.38, 0.48)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.68, 0.08, 0.10)
    material.emission_enabled = true
    material.emission = Color(0.18, 0.015, 0.02)
    mesh.material_override = material
    pickup.add_child(mesh)
    var mark := Label3D.new()
    mark.text = "+"
    mark.font_size = 64
    mark.pixel_size = 0.008
    mark.position = Vector3(0.0, 0.24, 0.0)
    mark.modulate = Color.WHITE
    pickup.add_child(mark)
    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 1.15
    collision.shape = sphere
    pickup.add_child(collision)
    pickup.body_entered.connect(_on_medkit_body_entered.bind(pickup))
    add_child(pickup)

func _on_player_died() -> void:
    is_game_over = true
    get_tree().paused = true
    _show_overlay("YOU DIED", "The darkness has claimed you. Try again?", false)

func _show_overlay(heading: String, message: String, show_resume: bool) -> void:
    if overlay_layer != null:
        overlay_layer.queue_free()
    overlay_layer = CanvasLayer.new()
    overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay_layer.layer = 20
    add_child(overlay_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.005, 0.008, 0.015, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_layer.add_child(shade)
    var panel := PanelContainer.new()
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    panel.custom_minimum_size = Vector2(330, 230)
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-165, -115)
    overlay_layer.add_child(panel)
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 14)
    panel.add_child(stack)
    var title := Label.new()
    title.text = heading
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    stack.add_child(title)
    var detail := Label.new()
    detail.text = message
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(detail)
    var save_button := Button.new()
    save_button.text = "SAVE GAME — SLOT 1"
    save_button.custom_minimum_size.y = 42
    save_button.process_mode = Node.PROCESS_MODE_ALWAYS
    save_button.pressed.connect(_save_game)
    stack.add_child(save_button)
    var load_button := Button.new()
    load_button.text = "LOAD GAME — SLOT 1"
    load_button.custom_minimum_size.y = 42
    load_button.process_mode = Node.PROCESS_MODE_ALWAYS
    load_button.pressed.connect(_load_game)
    stack.add_child(load_button)
    if show_resume:
        var resume := Button.new()
        resume.text = "RESUME"
        resume.custom_minimum_size.y = 44
        resume.process_mode = Node.PROCESS_MODE_ALWAYS
        resume.pressed.connect(toggle_pause)
        stack.add_child(resume)
    var craft_medkit := Button.new()
    craft_medkit.text = "CRAFT MEDKIT (2 CLOTH + 2 HERB)"
    craft_medkit.custom_minimum_size.y = 42
    craft_medkit.process_mode = Node.PROCESS_MODE_ALWAYS
    craft_medkit.pressed.connect(_craft_medkit)
    stack.add_child(craft_medkit)
    var craft_bandage := Button.new()
    craft_bandage.text = "CRAFT BANDAGE (1 CLOTH + 1 HERB)"
    craft_bandage.custom_minimum_size.y = 42
    craft_bandage.process_mode = Node.PROCESS_MODE_ALWAYS
    craft_bandage.pressed.connect(_craft_bandage)
    stack.add_child(craft_bandage)
    var eat_button := Button.new()
    eat_button.text = "USE FOOD"
    eat_button.custom_minimum_size.y = 38
    eat_button.process_mode = Node.PROCESS_MODE_ALWAYS
    eat_button.pressed.connect(_consume_food)
    stack.add_child(eat_button)
    var drink_button := Button.new()
    drink_button.text = "DRINK WATER"
    drink_button.custom_minimum_size.y = 38
    drink_button.process_mode = Node.PROCESS_MODE_ALWAYS
    drink_button.pressed.connect(_consume_water)
    stack.add_child(drink_button)
    var mode_button := Button.new()
    mode_button.text = "GAME MODE & DIFFICULTY"
    mode_button.custom_minimum_size.y = 42
    mode_button.process_mode = Node.PROCESS_MODE_ALWAYS
    mode_button.pressed.connect(_show_mode_selector)
    stack.add_child(mode_button)
    var map_button := Button.new()
    map_button.text = "CHANGE MAP"
    map_button.custom_minimum_size.y = 42
    map_button.process_mode = Node.PROCESS_MODE_ALWAYS
    map_button.pressed.connect(_show_map_selector)
    stack.add_child(map_button)
    var restart := Button.new()
    restart.text = "RESTART GAME"
    restart.custom_minimum_size.y = 44
    restart.process_mode = Node.PROCESS_MODE_ALWAYS
    restart.pressed.connect(_restart_game)
    stack.add_child(restart)

func _restart_game() -> void:
    if is_game_over:
        var player := get_node_or_null("Player")
        if player != null:
            get_tree().paused = false
            is_game_over = false
            player.is_dead = false
            player.position = StoryCampaign.checkpoint_position
            player.health = minf(player.max_health, StoryCampaign.checkpoint_health)
            player.stamina = player.max_stamina
            player.velocity = Vector3.ZERO
            player.health_changed.emit(player.health, player.max_health)
            player.stamina_changed.emit(player.stamina, player.max_stamina)
            if overlay_layer != null:
                overlay_layer.queue_free()
                overlay_layer = null
            return
    get_tree().paused = false
    get_tree().reload_current_scene()

var game_environment: Environment
var moon_light: DirectionalLight3D
var ambience_player: AudioStreamPlayer

func _setup_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.055, 0.075, 0.095)
    env.ambient_light_energy = 0.22
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.025, 0.035, 0.045)
    env.fog_density = 0.028
    env.fog_sky_affect = 0.35
    game_environment = env
    var world_env := WorldEnvironment.new()
    world_env.environment = env
    add_child(world_env)
    var moon := DirectionalLight3D.new()
    moon_light = moon
    moon.rotation_degrees = Vector3(-48, -28, 0)
    moon.light_color = Color(0.38, 0.48, 0.62)
    moon.light_energy = 0.19
    moon.directional_shadow_max_distance = 42.0
    moon.shadow_enabled = true
    add_child(moon)

func _is_main_trail(x: float, z: float, half_width: float) -> bool:
    # Keep the route from the spawn clearing toward the first encounter free of procedural obstacles.
    return absf(x) < half_width and z > -45.0 and z < 5.0

func _is_story_clear_zone(x: float, z: float, radius: float) -> bool:
    var locations := [
        Vector2(0.0, -29.0), Vector2(8.0, -33.0), Vector2(-9.0, -35.0),
        Vector2(1.0, -40.0), Vector2(-26.0, -38.0), Vector2(27.0, -40.0)
    ]
    for location in locations:
        if Vector2(x, z).distance_to(location) < radius:
            return true
    return false

func _start_forest_ambience() -> void:
    # Generate a lightweight seamless offline ambience loop; no external audio files are required.
    var stream := AudioStreamWAV.new()
    var sample_rate := 22050
    var seconds := 6
    var sample_count := sample_rate * seconds
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    for i in range(sample_count):
        var t := float(i) / float(sample_rate)
        var slow_wind := sin(TAU * 0.5 * t) * 0.018
        var low_wind := sin(TAU * 73.0 * t + sin(TAU * 0.5 * t) * 0.7) * 0.012
        var distant_wind := sin(TAU * 91.0 * t + sin(TAU * 0.333333 * t)) * 0.006
        var night_insects := (sin(TAU * 660.0 * t) + sin(TAU * 880.0 * t + 0.4)) * 0.0018
        var sample := clampf(slow_wind + low_wind + distant_wind + night_insects, -0.08, 0.08)
        bytes.encode_s16(i * 2, roundi(sample * 32767.0))
    stream.data = bytes
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = sample_count
    ambience_player = AudioStreamPlayer.new()
    ambience_player.name = "ForestAmbience"
    ambience_player.stream = stream
    ambience_player.volume_db = -18.0
    ambience_player.autoplay = true
    add_child(ambience_player)

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
        if Vector2(x, z).length() < 5.5 or _is_main_trail(x, z, 2.8) or _is_story_clear_zone(x, z, 5.0):
            continue
        _make_tree(Vector3(x, 0, z), rng.randf_range(0.75, 1.5))

func _make_forest_details() -> void:
    var trail := MeshInstance3D.new()
    var trail_mesh := PlaneMesh.new()
    trail_mesh.size = Vector2(5.6, 46.0)
    trail.mesh = trail_mesh
    trail.position = Vector3(0.0, 0.012, -18.0)
    var trail_material := StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.045, 0.041, 0.032)
    trail_material.roughness = 1.0
    trail.material_override = trail_material
    add_child(trail)
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261109
    var rock_material := StandardMaterial3D.new()
    rock_material.albedo_color = Color(0.075, 0.082, 0.078)
    rock_material.roughness = 1.0
    var shrub_material := StandardMaterial3D.new()
    shrub_material.albedo_color = Color(0.012, 0.032, 0.018)
    shrub_material.roughness = 1.0
    for i in range(70):
        var x := rng.randf_range(-43.0, 43.0)
        var z := rng.randf_range(-43.0, 43.0)
        if Vector2(x, z).length() < 4.5 or _is_main_trail(x, z, 2.2) or _is_story_clear_zone(x, z, 4.0):
            continue
        if rng.randf() < 0.58:
            var rock := MeshInstance3D.new()
            var rock_mesh := SphereMesh.new()
            var radius := rng.randf_range(0.18, 0.62)
            rock_mesh.radius = radius
            rock_mesh.height = radius * rng.randf_range(0.7, 1.4)
            rock.mesh = rock_mesh
            rock.position = Vector3(x, radius * 0.35, z)
            rock.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.0, TAU), rng.randf_range(-0.4, 0.4))
            rock.material_override = rock_material
            add_child(rock)
        else:
            var shrub := MeshInstance3D.new()
            var shrub_mesh := SphereMesh.new()
            var size := rng.randf_range(0.35, 0.85)
            shrub_mesh.radius = size
            shrub_mesh.height = size * 1.2
            shrub.mesh = shrub_mesh
            shrub.position = Vector3(x, size * 0.35, z)
            shrub.scale = Vector3(1.4, 0.65, 1.0)
            shrub.material_override = shrub_material
            add_child(shrub)
    for i in range(12):
        var x := rng.randf_range(-38.0, 38.0)
        var z := rng.randf_range(-38.0, 38.0)
        if Vector2(x, z).length() < 7.0 or _is_main_trail(x, z, 3.0) or _is_story_clear_zone(x, z, 4.0):
            continue
        var stump := MeshInstance3D.new()
        var stump_mesh := CylinderMesh.new()
        stump_mesh.top_radius = 0.08
        stump_mesh.bottom_radius = 0.16
        stump_mesh.height = rng.randf_range(1.0, 2.0)
        stump.mesh = stump_mesh
        stump.position = Vector3(x, stump_mesh.height * 0.5, z)
        stump.rotation.z = rng.randf_range(-0.18, 0.18)
        stump.material_override = rock_material
        add_child(stump)

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

func _spawn_monster(enemy_name: String = "Wanderer", spawn_position: Vector3 = Vector3(0.0, 0.1, -17.0), enemy_kind: String = "wanderer") -> void:
    var monster := CharacterBody3D.new()
    monster.name = enemy_name
    monster.set_script(MONSTER_SCRIPT)
    monster.position = spawn_position
    monster.configure_archetype(enemy_kind)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.62 if enemy_kind == "brute" else (0.36 if enemy_kind == "stalker" else 0.48)
    capsule.height = 2.65 if enemy_kind == "brute" else (2.05 if enemy_kind == "stalker" else 2.3)
    body.mesh = capsule
    body.position.y = 1.325 if enemy_kind == "brute" else (1.025 if enemy_kind == "stalker" else 1.15)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.055, 0.028, 0.018) if enemy_kind == "brute" else (Color(0.045, 0.012, 0.018) if enemy_kind == "stalker" else Color(0.012, 0.016, 0.018))
    mat.roughness = 1.0
    body.material_override = mat
    monster.add_child(body)
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.62 if enemy_kind == "brute" else (0.36 if enemy_kind == "stalker" else 0.48)
    shape.height = 2.65 if enemy_kind == "brute" else (2.05 if enemy_kind == "stalker" else 2.3)
    col.shape = shape
    col.position.y = 1.325 if enemy_kind == "brute" else (1.025 if enemy_kind == "stalker" else 1.15)
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
    status_label = Label.new()
    status_label.text = "HEALTH  100 / 100"
    status_label.position = Vector2(20, 54)
    status_label.add_theme_font_size_override("font_size", 13)
    layer.add_child(status_label)
    health_bar = ProgressBar.new()
    health_bar.position = Vector2(20, 76)
    health_bar.size = Vector2(245, 16)
    health_bar.max_value = 100
    health_bar.value = 100
    health_bar.show_percentage = false
    layer.add_child(health_bar)
    var stamina_label := Label.new()
    stamina_label.text = "STAMINA"
    stamina_label.position = Vector2(20, 96)
    stamina_label.add_theme_font_size_override("font_size", 12)
    layer.add_child(stamina_label)
    stamina_bar = ProgressBar.new()
    stamina_bar.position = Vector2(20, 116)
    stamina_bar.size = Vector2(245, 13)
    stamina_bar.max_value = 100
    stamina_bar.value = 100
    stamina_bar.show_percentage = false
    layer.add_child(stamina_bar)
    medkit_count_label = Label.new()
    medkit_count_label.text = "MEDKIT  x0  |  H / HEAL"
    medkit_count_label.position = Vector2(20, 136)
    medkit_count_label.add_theme_font_size_override("font_size", 12)
    layer.add_child(medkit_count_label)
    resources_label = Label.new()
    resources_label.text = "CLOTH 0  HERB 0  SCRAP 0  FOOD 0  WATER 0"
    resources_label.position = Vector2(20, 156)
    resources_label.add_theme_font_size_override("font_size", 11)
    layer.add_child(resources_label)
    story_label = Label.new()
    story_label.position = Vector2(20, 180)
    story_label.size = Vector2(430, 74)
    story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story_label.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0, 0.96))
    story_label.add_theme_font_size_override("font_size", 13)
    layer.add_child(story_label)
    mode_status_label = Label.new()
    mode_status_label.position = Vector2(20, 258)
    mode_status_label.add_theme_font_size_override("font_size", 12)
    mode_status_label.text = ModeManager.get_mode_name() + "  •  " + ModeManager.get_difficulty_name()
    layer.add_child(mode_status_label)
    survival_wave_label = Label.new()
    survival_wave_label.position = Vector2(20, 278)
    survival_wave_label.add_theme_font_size_override("font_size", 12)
    survival_wave_label.visible = ModeManager.current_mode == "survival"
    survival_wave_label.text = "SURVIVAL WAVE 1"
    layer.add_child(survival_wave_label)
    StoryCampaign.campaign_updated.connect(_on_story_campaign_updated)
    StoryCampaign.campaign_completed.connect(_on_story_campaign_completed)
    _on_story_campaign_updated(StoryCampaign.get_mission_title(), StoryCampaign.get_objective_text(), StoryCampaign.get_progress_text())
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-5, -12)
    crosshair.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.7))
    layer.add_child(crosshair)
    add_child(layer)
    var player := get_node_or_null("Player")
    if player != null:
        player.health_changed.connect(_on_health_changed)
        player.stamina_changed.connect(_on_stamina_changed)
        player.inventory_changed.connect(_on_inventory_changed)
        player.resources_changed.connect(_on_resources_changed)
        player.player_died.connect(_on_player_died)
    var settings_layer := CanvasLayer.new()
    settings_layer.set_script(preload("res://scripts/settings_ui.gd"))
    add_child(settings_layer)
    if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
        _make_mobile_controls(layer)

func _make_mobile_controls(layer: CanvasLayer) -> void:
    var screen := get_viewport().get_visible_rect().size
    var joystick := Control.new()
    joystick.name = "VirtualJoystick"
    joystick.set_script(preload("res://scripts/virtual_joystick.gd"))
    joystick.position = Vector2(22.0, screen.y - 202.0)
    joystick.size = Vector2(176.0, 176.0)
    joystick.add_to_group("touch_controls")
    joystick.set_meta("base_pos", joystick.position)
    joystick.set_meta("base_ratio", Vector2(joystick.position.x / maxf(1.0, screen.x), joystick.position.y / maxf(1.0, screen.y)))
    joystick.set_meta("base_size", joystick.size)
    joystick.connect("vector_changed", Callable(self, "_on_mobile_move_changed"))
    layer.add_child(joystick)
    var right_x := screen.x - 178.0
    var bottom_y := screen.y - 88.0
    _add_hold_button(layer, "RUN", "run", Vector2(right_x, bottom_y - 58.0), Vector2(74, 54))
    var light_button := Button.new()
    light_button.text = "LIGHT"
    light_button.add_to_group("touch_controls")
    light_button.set_meta("base_pos", Vector2(screen.x - 92.0, bottom_y - 58.0))
    light_button.set_meta("base_ratio", Vector2((screen.x - 92.0) / maxf(1.0, screen.x), (bottom_y - 58.0) / maxf(1.0, screen.y)))
    light_button.set_meta("base_size", Vector2(76, 54))
    light_button.position = light_button.get_meta("base_pos")
    light_button.size = light_button.get_meta("base_size")
    light_button.focus_mode = Control.FOCUS_NONE
    light_button.pressed.connect(_toggle_player_flashlight)
    layer.add_child(light_button)
    var heal_button := Button.new()
    heal_button.text = "HEAL"
    heal_button.add_to_group("touch_controls")
    heal_button.set_meta("base_pos", Vector2(screen.x - 92.0, bottom_y - 120.0))
    heal_button.set_meta("base_ratio", Vector2((screen.x - 92.0) / maxf(1.0, screen.x), (bottom_y - 120.0) / maxf(1.0, screen.y)))
    heal_button.set_meta("base_size", Vector2(76, 54))
    heal_button.position = heal_button.get_meta("base_pos")
    heal_button.size = heal_button.get_meta("base_size")
    heal_button.focus_mode = Control.FOCUS_NONE
    heal_button.pressed.connect(_use_player_medkit)
    layer.add_child(heal_button)

func _on_mobile_move_changed(value: Vector2) -> void:
    var player := get_node_or_null("Player")
    if player != null and player.has_method("set_mobile_move_vector"):
        player.set_mobile_move_vector(value)

func _add_hold_button(layer: CanvasLayer, caption: String, action: StringName, pos: Vector2, button_size: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = button_size
    button.add_to_group("touch_controls")
    button.set_meta("base_pos", pos)
    var viewport_size := get_viewport().get_visible_rect().size
    button.set_meta("base_ratio", Vector2(pos.x / maxf(1.0, viewport_size.x), pos.y / maxf(1.0, viewport_size.y)))
    button.set_meta("base_size", button_size)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)
    button.button_down.connect(_press_action.bind(action))
    button.button_up.connect(_release_action.bind(action))
    layer.add_child(button)

func _press_action(action: StringName) -> void:
    Input.action_press(action)

func _release_action(action: StringName) -> void:
    Input.action_release(action)

func apply_graphics_quality(level: String) -> void:
    if game_environment == null:
        return
    var mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
    match level:
        "Low":
            game_environment.ambient_light_energy = 0.30
            game_environment.fog_enabled = false
            if moon_light: moon_light.shadow_enabled = false
        "Medium":
            game_environment.ambient_light_energy = 0.25
            game_environment.fog_enabled = true
            game_environment.fog_density = 0.02
            if moon_light: moon_light.shadow_enabled = false
        "High":
            game_environment.ambient_light_energy = 0.22
            game_environment.fog_enabled = true
            game_environment.fog_density = 0.035
            if moon_light: moon_light.shadow_enabled = true
        "Ultra":
            game_environment.ambient_light_energy = 0.20
            game_environment.fog_enabled = true
            game_environment.fog_density = 0.045
            if moon_light: moon_light.shadow_enabled = true
    var player := get_node_or_null("Player")
    if player:
        var lamp := player.get_node_or_null("Head/Camera3D/Flashlight")
        if lamp:
            lamp.shadow_enabled = level in ["High", "Ultra"]


func _craft_medkit() -> void:
    var player := get_node_or_null("Player")
    if player != null:
        player.craft_item("medkit")

func _craft_bandage() -> void:
    var player := get_node_or_null("Player")
    if player != null:
        player.craft_item("bandage")

func _consume_food() -> void:
    var player := get_node_or_null("Player")
    if player != null:
        player.consume_item("food")

func _consume_water() -> void:
    var player := get_node_or_null("Player")
    if player != null:
        player.consume_item("water")

func _use_player_medkit() -> void:
    var player := get_node_or_null("Player")
    if player != null and player.has_method("use_medkit"):
        player.use_medkit()

func _toggle_player_flashlight() -> void:
    var player := get_node_or_null("Player")
    if player != null and player.has_method("_toggle_flashlight"):
        player._toggle_flashlight()

func _vector3_to_array(value: Vector3) -> Array:
    return [value.x, value.y, value.z]

func _array_to_vector3(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
    if typeof(value) != TYPE_ARRAY or value.size() != 3:
        return fallback
    return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _save_game() -> void:
    var player := get_node_or_null("Player")
    if player == null:
        return
    var pickup_positions: Array = []
    for pickup in get_tree().get_nodes_in_group("save_pickups"):
        if is_instance_valid(pickup):
            pickup_positions.append(_vector3_to_array(pickup.position))
    var resource_pickups: Array = []
    for pickup in get_tree().get_nodes_in_group("save_resource_pickups"):
        if is_instance_valid(pickup):
            resource_pickups.append({
                "position": _vector3_to_array(pickup.position),
                "item": str(pickup.get_meta("item")),
                "amount": int(pickup.get_meta("amount"))
            })
    var enemy_positions: Dictionary = {}
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(enemy):
            enemy_positions[enemy.name] = _vector3_to_array(enemy.position)
    var payload := {
        "player_position": _vector3_to_array(player.position),
        "player_yaw": player.rotation.y,
        "player_pitch": float(player.look_pitch),
        "health": float(player.health),
        "stamina": float(player.stamina),
        "medkits": int(player.medkits),
        "resources": player.resources.duplicate(true),
        "flashlight_on": bool(player.flashlight_on),
        "enemy_positions": enemy_positions,
        "medkit_pickups": pickup_positions,
        "resource_pickups": resource_pickups,
        "story_campaign": StoryCampaign.get_save_data()
    }
    var saved := SaveManager.save_slot(1, payload)
    if saved:
        _show_overlay("GAME SAVED", "Your offline progress was saved to Slot 1.", true)
        get_tree().paused = true
    else:
        _show_overlay("SAVE FAILED", "The save could not be written. Check device storage.", true)
        get_tree().paused = true

func _load_game() -> void:
    var payload: Dictionary = SaveManager.load_slot(1)
    if payload.is_empty():
        _show_overlay("NO SAVE FOUND", "Slot 1 is empty or the save is incompatible.", true)
        get_tree().paused = true
        return
    var player := get_node_or_null("Player")
    if player == null:
        return
    get_tree().paused = false
    is_game_over = false
    if overlay_layer != null:
        overlay_layer.queue_free()
        overlay_layer = null
    player.position = _array_to_vector3(payload.get("player_position", []), player.position)
    player.rotation.y = float(payload.get("player_yaw", player.rotation.y))
    player.look_pitch = clampf(float(payload.get("player_pitch", 0.0)), deg_to_rad(-82.0), deg_to_rad(82.0))
    player.head.rotation.x = player.look_pitch
    player.health = clampf(float(payload.get("health", 100.0)), 0.0, player.max_health)
    player.stamina = clampf(float(payload.get("stamina", 100.0)), 0.0, player.max_stamina)
    player.medkits = maxi(0, int(payload.get("medkits", 0)))
    var saved_resources: Variant = payload.get("resources", {})
    if typeof(saved_resources) == TYPE_DICTIONARY:
        for item in player.resources.keys():
            player.resources[item] = maxi(0, int(saved_resources.get(item, 0)))
    player.is_dead = player.health <= 0.0
    player.flashlight_on = bool(payload.get("flashlight_on", true))
    player.lamp.visible = player.flashlight_on
    player.velocity = Vector3.ZERO
    player.health_changed.emit(player.health, player.max_health)
    player.stamina_changed.emit(player.stamina, player.max_stamina)
    player.inventory_changed.emit(player.medkits)
    player.resources_changed.emit(player.resources.duplicate(true))
    var saved_story: Variant = payload.get("story_campaign", {})
    if typeof(saved_story) == TYPE_DICTIONARY:
        StoryCampaign.load_save_data(saved_story)
        for trigger in get_tree().get_nodes_in_group("story_triggers"):
            if is_instance_valid(trigger) and StoryCampaign.is_objective_done(str(trigger.get_meta("objective_id", ""))):
                trigger.queue_free()
    var saved_enemies: Variant = payload.get("enemy_positions", {})
    if typeof(saved_enemies) == TYPE_DICTIONARY:
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if is_instance_valid(enemy) and saved_enemies.has(enemy.name):
                enemy.position = _array_to_vector3(saved_enemies[enemy.name], enemy.position)
                enemy.velocity = Vector3.ZERO
    elif payload.has("monster_position"):
        # Backward compatibility for saves created before multiple enemy support.
        var legacy_enemy := get_node_or_null("Wanderer")
        if legacy_enemy != null:
            legacy_enemy.position = _array_to_vector3(payload.get("monster_position", []), legacy_enemy.position)
            legacy_enemy.velocity = Vector3.ZERO
    for pickup in get_tree().get_nodes_in_group("save_pickups"):
        if is_instance_valid(pickup):
            pickup.queue_free()
    for saved_position in payload.get("medkit_pickups", []):
        var position_3d := _array_to_vector3(saved_position)
        _spawn_medkit(position_3d - Vector3(0.0, 0.55, 0.0))
    for pickup in get_tree().get_nodes_in_group("save_resource_pickups"):
        if is_instance_valid(pickup):
            pickup.queue_free()
    for saved_pickup in payload.get("resource_pickups", []):
        if typeof(saved_pickup) == TYPE_DICTIONARY:
            var resource_position := _array_to_vector3(saved_pickup.get("position", []))
            var resource_item := str(saved_pickup.get("item", ""))
            var resource_amount := maxi(1, int(saved_pickup.get("amount", 1)))
            if player.resources.has(resource_item):
                _spawn_resource_pickup(resource_position - Vector3(0.0, 0.55, 0.0), resource_item, resource_amount)
    if player.is_dead:
        _on_player_died()

func _add_map_block(block_name: String, block_position: Vector3, block_size: Vector3, block_color: Color, solid: bool = true) -> void:
    var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
    root.name = block_name
    root.position = block_position
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = block_size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = block_color
    material.roughness = 0.92
    mesh.material_override = material
    root.add_child(mesh)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = block_size
        collision.shape = shape
        root.add_child(collision)
    add_child(root)

func _add_map_light(light_position: Vector3, light_color: Color, energy: float, radius: float) -> void:
    var lamp := OmniLight3D.new()
    lamp.position = light_position
    lamp.light_color = light_color
    lamp.light_energy = energy
    lamp.omni_range = radius
    lamp.shadow_enabled = false
    add_child(lamp)

func _make_hospital_map() -> void:
    _add_map_block("HospitalOuterNorth", Vector3(0, 2.0, -28), Vector3(42, 4, 1), Color(0.22, 0.25, 0.28))
    _add_map_block("HospitalOuterSouth", Vector3(0, 2.0, 12), Vector3(42, 4, 1), Color(0.22, 0.25, 0.28))
    _add_map_block("HospitalOuterWest", Vector3(-21, 2.0, -8), Vector3(1, 4, 40), Color(0.19, 0.22, 0.25))
    _add_map_block("HospitalOuterEast", Vector3(21, 2.0, -8), Vector3(1, 4, 40), Color(0.19, 0.22, 0.25))
    for z in [-20.0, -8.0, 4.0]:
        _add_map_block("HospitalRoomDivider", Vector3(-14, 1.8, z), Vector3(14, 3.6, 0.45), Color(0.28, 0.30, 0.31))
        _add_map_block("HospitalRoomDivider", Vector3(14, 1.8, z), Vector3(14, 3.6, 0.45), Color(0.28, 0.30, 0.31))
    for x in [-15.0, 15.0]:
        for z in [-23.0, -11.0, 1.0, 9.0]:
            _add_map_block("HospitalBed", Vector3(x, 0.55, z), Vector3(3.2, 0.45, 1.5), Color(0.42, 0.48, 0.51), false)
    for z in [-23.0, -11.0, 1.0, 9.0]:
        _add_map_light(Vector3(0, 3.0, z), Color(0.56, 0.72, 0.82), 0.8, 12.0)
    _add_map_block("HospitalReception", Vector3(0, 0.65, 8), Vector3(8, 1.3, 2), Color(0.24, 0.29, 0.31), false)
    _add_map_block("HospitalSign", Vector3(0, 3.2, -27.2), Vector3(9, 0.8, 0.25), Color(0.36, 0.08, 0.08), false)

func _make_village_map() -> void:
    var hut_positions := [Vector3(-14, 0, -18), Vector3(13, 0, -20), Vector3(-18, 0, 4), Vector3(18, 0, 7), Vector3(0, 0, -34), Vector3(0, 0, 25)]
    for i in range(hut_positions.size()):
        var pos: Vector3 = hut_positions[i]
        _add_map_block("VillageHut_%d" % i, pos + Vector3(0, 1.6, 0), Vector3(8, 3.2, 7), Color(0.16, 0.12, 0.085))
        _add_map_block("VillageRoof_%d" % i, pos + Vector3(0, 3.55, 0), Vector3(9, 0.55, 8), Color(0.09, 0.075, 0.06), false)
        _add_map_block("VillageDoor_%d" % i, pos + Vector3(0, 1.0, 3.56), Vector3(1.5, 2.0, 0.15), Color(0.045, 0.035, 0.025), false)
    _add_map_block("VillageWell", Vector3(0, 0.5, -4), Vector3(3.0, 1.0, 3.0), Color(0.24, 0.25, 0.22), false)
    _add_map_block("VillageSquareMarker", Vector3(0, 0.03, -4), Vector3(15, 0.06, 15), Color(0.10, 0.095, 0.075), false)
    for x in [-24.0, -8.0, 8.0, 24.0]:
        _add_map_light(Vector3(x, 3.2, -4), Color(1.0, 0.53, 0.22), 0.65, 10.0)
    _add_map_block("VillageChurch", Vector3(0, 2.2, 39), Vector3(14, 4.4, 10), Color(0.18, 0.17, 0.15))
    _add_map_block("VillageChurchTower", Vector3(0, 6.0, 39), Vector3(3, 4, 3), Color(0.12, 0.11, 0.10), false)

func _make_bunker_map() -> void:
    var wall_color := Color(0.20, 0.23, 0.24)
    _add_map_block("BunkerWestWall", Vector3(-9, 2.0, -8), Vector3(0.8, 4, 76), wall_color)
    _add_map_block("BunkerEastWall", Vector3(9, 2.0, -8), Vector3(0.8, 4, 76), wall_color)
    _add_map_block("BunkerNorthWall", Vector3(0, 2.0, -46), Vector3(18, 4, 0.8), wall_color)
    _add_map_block("BunkerSouthWall", Vector3(0, 2.0, 30), Vector3(18, 4, 0.8), wall_color)
    for z in [-34.0, -20.0, -6.0, 8.0, 22.0]:
        _add_map_block("BunkerSidePartition", Vector3(-5.8, 1.8, z), Vector3(4.4, 3.6, 0.5), wall_color)
        _add_map_block("BunkerSidePartition", Vector3(5.8, 1.8, z), Vector3(4.4, 3.6, 0.5), wall_color)
        _add_map_light(Vector3(0, 3.3, z), Color(0.42, 0.78, 0.72), 0.72, 11.0)
    for z in [-39.0, -25.0, -11.0, 3.0, 17.0]:
        _add_map_block("BunkerCrate", Vector3(-5.8, 0.8, z), Vector3(2.2, 1.6, 2.2), Color(0.20, 0.24, 0.21), false)
        _add_map_block("BunkerConsole", Vector3(5.5, 1.0, z), Vector3(2.4, 2.0, 1.0), Color(0.10, 0.20, 0.19), false)
    _add_map_block("BunkerBlastDoor", Vector3(0, 2.0, -45.2), Vector3(7, 3.8, 0.6), Color(0.10, 0.14, 0.15), false)

func _show_map_selector() -> void:
    if overlay_layer != null:
        overlay_layer.queue_free()
    overlay_layer = CanvasLayer.new()
    overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay_layer.layer = 22
    add_child(overlay_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.005, 0.008, 0.015, 0.92)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_layer.add_child(shade)
    var panel := PanelContainer.new()
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    panel.custom_minimum_size = Vector2(340, 320)
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-170, -160)
    overlay_layer.add_child(panel)
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 10)
    panel.add_child(stack)
    var title := Label.new()
    title.text = "SELECT LOCATION"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    stack.add_child(title)
    for map_id in ["forest", "hospital", "village", "bunker"]:
        var button := Button.new()
        button.text = MapManager.get_map_name(map_id)
        button.custom_minimum_size.y = 46
        button.process_mode = Node.PROCESS_MODE_ALWAYS
        button.pressed.connect(_select_map.bind(map_id))
        stack.add_child(button)
    var back := Button.new()
    back.text = "BACK"
    back.custom_minimum_size.y = 42
    back.process_mode = Node.PROCESS_MODE_ALWAYS
    back.pressed.connect(_show_overlay.bind("PAUSED", "The forest is waiting. Take a breath.", true))
    stack.add_child(back)

func _show_mode_selector() -> void:
    if overlay_layer != null:
        overlay_layer.queue_free()
    overlay_layer = CanvasLayer.new()
    overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay_layer.layer = 23
    add_child(overlay_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.005, 0.008, 0.015, 0.93)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_layer.add_child(shade)
    var panel := PanelContainer.new()
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    panel.custom_minimum_size = Vector2(340, 410)
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-170, -205)
    overlay_layer.add_child(panel)
    var scroll := ScrollContainer.new()
    panel.add_child(scroll)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(stack)
    var title := Label.new()
    title.text = "GAME MODE & DIFFICULTY"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 21)
    stack.add_child(title)
    var mode_label := Label.new()
    mode_label.text = "SELECT GAME MODE"
    stack.add_child(mode_label)
    var mode_picker := OptionButton.new()
    var mode_ids := ["story_campaign", "survival", "free_explore", "nightmare", "custom", "coop"]
    for mode_id in mode_ids:
        var mode_name := ModeManager.get_mode_name_for(mode_id)
        if mode_id == "coop":
            mode_name += " — COMING SOON"
        mode_picker.add_item(mode_name)
    mode_picker.select(maxi(0, mode_ids.find(ModeManager.current_mode)))
    mode_picker.set_meta("mode_ids", mode_ids)
    stack.add_child(mode_picker)
    var difficulty_label := Label.new()
    difficulty_label.text = "DIFFICULTY"
    stack.add_child(difficulty_label)
    var difficulty_picker := OptionButton.new()
    var difficulty_ids := ["easy", "normal", "hard", "nightmare", "dynamic"]
    for difficulty_id in difficulty_ids:
        difficulty_picker.add_item(ModeManager.get_difficulty_name_for(difficulty_id))
    difficulty_picker.select(maxi(0, difficulty_ids.find(ModeManager.current_difficulty)))
    difficulty_picker.set_meta("difficulty_ids", difficulty_ids)
    stack.add_child(difficulty_picker)
    var note := Label.new()
    note.text = "Co-op is not available yet. Custom mode currently uses the selected difficulty with balanced default rules."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(note)
    var apply := Button.new()
    apply.text = "APPLY & RESTART"
    apply.custom_minimum_size.y = 46
    apply.process_mode = Node.PROCESS_MODE_ALWAYS
    apply.pressed.connect(_apply_mode_selection.bind(mode_picker, difficulty_picker))
    stack.add_child(apply)
    var back := Button.new()
    back.text = "BACK"
    back.custom_minimum_size.y = 40
    back.process_mode = Node.PROCESS_MODE_ALWAYS
    back.pressed.connect(_show_overlay.bind("PAUSED", "Game paused.", true))
    stack.add_child(back)

func _apply_mode_selection(mode_picker: OptionButton, difficulty_picker: OptionButton) -> void:
    var mode_ids: Array = mode_picker.get_meta("mode_ids", [])
    var difficulty_ids: Array = difficulty_picker.get_meta("difficulty_ids", [])
    var selected_mode := str(mode_ids[mode_picker.selected])
    var selected_difficulty := str(difficulty_ids[difficulty_picker.selected])
    if selected_mode == "coop":
        _show_overlay("CO-OP COMING SOON", "Online co-op needs a dedicated multiplayer server. It is not enabled in this build.", true)
        get_tree().paused = true
        return
    ModeManager.set_mode(selected_mode)
    ModeManager.set_difficulty(selected_difficulty)
    get_tree().paused = false
    get_tree().reload_current_scene()

func _select_map(map_id: String) -> void:
    if not MapManager.select_map(map_id):
        return
    get_tree().paused = false
    get_tree().reload_current_scene()

func _make_story_objectives() -> void:
    _spawn_story_trigger("reach_radio", "ABANDONED RADIO", Vector3(0.0, 0.0, -29.0), Color(0.25, 0.72, 1.0))
    _spawn_story_trigger("evidence_1", "RADIO LOG 01", Vector3(8.0, 0.0, -33.0), Color(0.65, 0.82, 1.0))
    _spawn_story_trigger("evidence_2", "RADIO LOG 02", Vector3(-9.0, 0.0, -35.0), Color(0.65, 0.82, 1.0))
    _spawn_story_trigger("evidence_3", "RADIO LOG 03", Vector3(1.0, 0.0, -40.0), Color(0.65, 0.82, 1.0))
    _spawn_story_trigger("signal_tower", "SIGNAL TOWER", Vector3(-26.0, 0.0, -38.0), Color(0.35, 0.9, 0.65))
    _spawn_story_trigger("extraction", "EXTRACTION POINT", Vector3(27.0, 0.0, -40.0), Color(1.0, 0.68, 0.28))

func _spawn_story_trigger(objective_id: String, marker_text: String, marker_position: Vector3, marker_color: Color) -> void:
    if StoryCampaign.is_objective_done(objective_id):
        return
    var trigger := Area3D.new()
    trigger.name = "Story_" + objective_id
    trigger.add_to_group("story_triggers")
    trigger.set_meta("objective_id", objective_id)
    trigger.position = marker_position
    var marker := MeshInstance3D.new()
    var orb := SphereMesh.new()
    orb.radius = 0.42
    orb.height = 0.84
    marker.mesh = orb
    var material := StandardMaterial3D.new()
    material.albedo_color = marker_color
    material.emission_enabled = true
    material.emission = marker_color * 0.55
    marker.material_override = material
    marker.position.y = 1.15
    trigger.add_child(marker)
    var label := Label3D.new()
    label.text = marker_text
    label.font_size = 30
    label.pixel_size = 0.008
    label.position.y = 2.0
    label.modulate = marker_color
    trigger.add_child(label)
    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 2.4
    collision.shape = sphere
    trigger.add_child(collision)
    trigger.body_entered.connect(_on_story_trigger_body_entered.bind(trigger, objective_id))
    add_child(trigger)

func _on_story_trigger_body_entered(body: Node3D, trigger: Area3D, objective_id: String) -> void:
    if body.name != "Player" or not is_instance_valid(trigger):
        return
    var accepted := false
    if objective_id.begins_with("evidence_"):
        accepted = StoryCampaign.mark_evidence_found(objective_id)
    else:
        accepted = StoryCampaign.complete_objective(objective_id)
    if not accepted:
        return
    StoryCampaign.set_checkpoint(body.global_position, float(body.health))
    trigger.queue_free()
    if objective_id == "reach_radio":
        _show_story_message("RADIO DISCOVERED", "A broken transmission repeats: 'Tower seven... extraction before dawn.'")
    elif objective_id.begins_with("evidence_"):
        _show_story_message("EVIDENCE RECOVERED", "A fragment of the final transmission has been recovered.")
    elif objective_id == "signal_tower":
        _show_story_message("SIGNAL RESTORED", "The tower answers. Something in the forest answers back.")
    elif objective_id == "extraction":
        _show_story_message("CAMPAIGN COMPLETE", "You escaped the Dark Forest. The transmission is not over...")
        get_tree().paused = true

func _on_story_campaign_updated(mission_title: String, objective_text: String, progress_text: String) -> void:
    if story_label != null:
        story_label.text = mission_title + "\n" + objective_text + "  [" + progress_text + "]"

func _on_story_campaign_completed() -> void:
    if story_label != null:
        story_label.text = "CAMPAIGN COMPLETE\nYou escaped the Dark Forest."

func _show_story_message(heading: String, message: String) -> void:
    if overlay_layer != null:
        overlay_layer.queue_free()
    overlay_layer = CanvasLayer.new()
    overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay_layer.layer = 25
    add_child(overlay_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.004, 0.008, 0.018, 0.9)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_layer.add_child(shade)
    var panel := PanelContainer.new()
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    panel.custom_minimum_size = Vector2(320, 190)
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-160, -95)
    overlay_layer.add_child(panel)
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 16)
    panel.add_child(stack)
    var title := Label.new()
    title.text = heading
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    stack.add_child(title)
    var detail := Label.new()
    detail.text = message
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stack.add_child(detail)
    var continue_button := Button.new()
    continue_button.text = "CONTINUE"
    continue_button.custom_minimum_size.y = 44
    continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
    continue_button.pressed.connect(_close_overlay)
    stack.add_child(continue_button)
    get_tree().paused = true

