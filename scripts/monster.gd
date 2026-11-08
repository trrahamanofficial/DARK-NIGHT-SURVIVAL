extends CharacterBody3D

@export var wander_speed := 1.15
@export var notice_distance := 13.0
var player: Node3D
var target_point := Vector3.ZERO
var change_timer := 0.0

func _ready() -> void:
    _choose_target()

func _physics_process(delta: float) -> void:
    if player == null:
        player = get_tree().current_scene.get_node_or_null("Player")
    change_timer -= delta
    var destination := target_point
    var speed := wander_speed
    if player != null and global_position.distance_to(player.global_position) < notice_distance:
        destination = player.global_position
        speed = wander_speed * 1.35
    elif change_timer <= 0.0 or global_position.distance_to(target_point) < 1.4:
        _choose_target()
        destination = target_point
    var flat := destination - global_position
    flat.y = 0
    if flat.length() > 0.2:
        velocity.x = flat.normalized().x * speed
        velocity.z = flat.normalized().z * speed
        look_at(global_position + Vector3(flat.x, 0, flat.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0, 3 * delta)
        velocity.z = move_toward(velocity.z, 0, 3 * delta)
    velocity.y = -0.5
    move_and_slide()

func _choose_target() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    target_point = Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25))
    change_timer = rng.randf_range(4.0, 8.0)
