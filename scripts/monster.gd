extends CharacterBody3D

@export var wander_speed := 1.15
@export var chase_speed := 2.35
@export var notice_distance := 18.0
@export var attack_distance := 1.65
@export var attack_damage := 12.0
@export var attack_interval := 1.45

var player: Node3D
var target_point := Vector3.ZERO
var change_timer := 0.0
var attack_timer := 0.0

func _ready() -> void:
    _choose_target()

func _physics_process(delta: float) -> void:
    if get_tree().paused:
        return
    if player == null:
        player = get_tree().current_scene.get_node_or_null("Player")
    if player == null or (player.has_method("is_dead") and player.is_dead):
        velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
        velocity.y = -0.5
        move_and_slide()
        return

    attack_timer = maxf(0.0, attack_timer - delta)
    change_timer -= delta
    var distance_to_player := global_position.distance_to(player.global_position)
    var destination := target_point
    var speed := wander_speed
    var chasing := distance_to_player < notice_distance

    if chasing:
        destination = player.global_position
        speed = chase_speed
        if distance_to_player <= attack_distance and attack_timer <= 0.0:
            if player.has_method("take_damage"):
                player.take_damage(attack_damage)
            attack_timer = attack_interval
    elif change_timer <= 0.0 or global_position.distance_to(target_point) < 1.4:
        _choose_target()
        destination = target_point

    var flat := destination - global_position
    flat.y = 0.0
    if flat.length() > 0.2 and not (chasing and distance_to_player <= attack_distance):
        velocity.x = flat.normalized().x * speed
        velocity.z = flat.normalized().z * speed
        look_at(global_position + Vector3(flat.x, 0.0, flat.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
    velocity.y = -0.5
    move_and_slide()

func _choose_target() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    target_point = Vector3(rng.randf_range(-25.0, 25.0), 0.0, rng.randf_range(-25.0, 25.0))
    change_timer = rng.randf_range(4.0, 8.0)
