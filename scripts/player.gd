extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal inventory_changed(medkit_count: int)
signal resources_changed(resources: Dictionary)
signal player_died

@export var walk_speed := 4.2
@export var run_speed := 6.8
@export var mouse_sensitivity := 0.0022
@export var touch_sensitivity := 0.004
@export var gravity := 18.0
@export var max_health := 100.0
@export var max_stamina := 100.0
@export var stamina_drain_per_second := 22.0
@export var stamina_regen_per_second := 15.0
@export var medkit_heal_amount := 40.0

var health := 100.0
var stamina := 100.0
var medkits := 0
var resources: Dictionary = {"cloth": 0, "herb": 0, "scrap": 0, "food": 0, "water": 0}
var look_pitch := 0.0
var flashlight_on := true
var is_dead := false
var damage_cooldown := 0.0
var mobile_move_vector := Vector2.ZERO
var touch_sensitivity_multiplier := 1.0
var touch_look_on_right := true

@onready var head: Node3D = $Head
@onready var lamp: SpotLight3D = $Head/Camera3D/Flashlight

func _ready() -> void:
    health = max_health
    stamina = max_stamina
    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, max_stamina)
    inventory_changed.emit(medkits)
    resources_changed.emit(resources.duplicate(true))
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
    if is_dead or get_tree().paused:
        return
    if damage_cooldown > 0.0:
        damage_cooldown = maxf(0.0, damage_cooldown - delta)
    if Input.is_action_pressed("run") and stamina > 0.5:
        stamina = maxf(0.0, stamina - stamina_drain_per_second * delta)
    else:
        stamina = minf(max_stamina, stamina + stamina_regen_per_second * delta)
    stamina_changed.emit(stamina, max_stamina)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        var world := get_tree().current_scene
        if world != null and world.has_method("toggle_pause"):
            world.toggle_pause()
            get_viewport().set_input_as_handled()
            return
    if is_dead or get_tree().paused:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _look(event.relative, mouse_sensitivity)
    elif event is InputEventScreenDrag:
        var look_side_start := 0.52 if touch_look_on_right else 0.0
        var look_side_end := 1.0 if touch_look_on_right else 0.48
        var touch_x_ratio := event.position.x / get_viewport().get_visible_rect().size.x
        if touch_x_ratio >= look_side_start and touch_x_ratio <= look_side_end:
            _look(event.relative, touch_sensitivity * touch_sensitivity_multiplier)
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
        _toggle_flashlight()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_H:
        use_medkit()

func set_mobile_move_vector(value: Vector2) -> void:
    mobile_move_vector = value.limit_length(1.0)

func set_touch_sensitivity_multiplier(value: float) -> void:
    touch_sensitivity_multiplier = clampf(value, 0.5, 2.0)

func set_touch_look_on_right(value: bool) -> void:
    touch_look_on_right = value

func _look(delta_position: Vector2, sensitivity: float) -> void:
    rotate_y(-delta_position.x * sensitivity)
    look_pitch = clamp(look_pitch - delta_position.y * sensitivity, deg_to_rad(-82), deg_to_rad(82))
    head.rotation.x = look_pitch

func _toggle_flashlight() -> void:
    flashlight_on = not flashlight_on
    lamp.visible = flashlight_on

func take_damage(amount: float) -> void:
    if is_dead or amount <= 0.0 or damage_cooldown > 0.0:
        return
    health = maxf(0.0, health - amount)
    damage_cooldown = 0.65
    health_changed.emit(health, max_health)
    if health <= 0.0:
        _die()

func heal(amount: float) -> void:
    if is_dead or amount <= 0.0:
        return
    health = minf(max_health, health + amount)
    health_changed.emit(health, max_health)

func restore_stamina(amount: float) -> void:
    if is_dead or amount <= 0.0:
        return
    stamina = minf(max_stamina, stamina + amount)
    stamina_changed.emit(stamina, max_stamina)

func add_medkit(count: int = 1) -> void:
    if is_dead or count <= 0:
        return
    medkits += count
    inventory_changed.emit(medkits)

func use_medkit() -> void:
    if is_dead or medkits <= 0 or health >= max_health:
        return
    medkits -= 1
    heal(medkit_heal_amount)
    inventory_changed.emit(medkits)


func add_resource(item: String, amount: int = 1) -> void:
    if is_dead or amount <= 0 or not resources.has(item):
        return
    resources[item] = int(resources[item]) + amount
    resources_changed.emit(resources.duplicate(true))

func craft_item(recipe: String) -> bool:
    if is_dead:
        return false
    match recipe:
        "medkit":
            if int(resources.cloth) < 2 or int(resources.herb) < 2:
                return false
            resources.cloth -= 2
            resources.herb -= 2
            medkits += 1
            inventory_changed.emit(medkits)
        "bandage":
            if int(resources.cloth) < 1 or int(resources.herb) < 1:
                return false
            resources.cloth -= 1
            resources.herb -= 1
            heal(20.0)
        _:
            return false
    resources_changed.emit(resources.duplicate(true))
    return true

func consume_item(item: String) -> bool:
    if is_dead:
        return false
    if item == "food" and int(resources.food) > 0:
        resources.food -= 1
        restore_stamina(35.0)
    elif item == "water" and int(resources.water) > 0:
        resources.water -= 1
        restore_stamina(20.0)
    else:
        return false
    resources_changed.emit(resources.duplicate(true))
    return true

func _die() -> void:
    if is_dead:
        return
    is_dead = true
    velocity = Vector3.ZERO
    Input.action_release("run")
    Input.action_release("move_forward")
    Input.action_release("move_back")
    Input.action_release("move_left")
    Input.action_release("move_right")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    player_died.emit()

func _physics_process(delta: float) -> void:
    if is_dead or get_tree().paused:
        return
    var input_dir := mobile_move_vector
    if input_dir.length() < 0.05:
        input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var can_run := Input.is_action_pressed("run") and stamina > 0.5
    var speed := run_speed if can_run else walk_speed
    velocity.x = move_toward(velocity.x, direction.x * speed, 18.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * speed, 18.0 * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()
