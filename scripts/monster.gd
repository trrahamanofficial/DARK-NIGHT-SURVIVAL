extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal enemy_died(enemy_name: String)

enum AIState { PATROL, INVESTIGATE, CHASE, ATTACK, RETREAT }

@export var archetype := "wanderer"
@export var max_health := 90.0
@export var wander_speed := 1.15
@export var chase_speed := 2.35
@export var notice_distance := 18.0
@export var hearing_distance := 9.0
@export var lose_target_seconds := 3.5
@export var attack_distance := 1.65
@export var attack_damage := 12.0
@export var attack_interval := 1.45
@export var retreat_health_ratio := 0.0

var health := 90.0
var player: Node3D
var target_point := Vector3.ZERO
var change_timer := 0.0
var attack_timer := 0.0
var attack_windup := 0.0
var target_memory_timer := 0.0
var state: AIState = AIState.PATROL
var is_dead := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    add_to_group("enemies")
    rng.randomize()
    health = max_health
    _choose_target()

func _apply_mode_tuning() -> void:
    var player_health := 100.0
    var player_node := get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
    if player_node != null:
        player_health = float(player_node.health)
    max_health *= ModeManager.get_enemy_health_multiplier()
    health = max_health
    attack_damage *= ModeManager.get_enemy_damage_multiplier(player_health)
    var detection_multiplier := ModeManager.get_enemy_detection_multiplier()
    notice_distance *= detection_multiplier
    hearing_distance *= detection_multiplier

func configure_archetype(kind: String) -> void:
    archetype = kind
    match archetype:
        "stalker":
            max_health = 65.0
            wander_speed = 1.55
            chase_speed = 3.35
            notice_distance = 22.0
            hearing_distance = 13.0
            attack_distance = 1.55
            attack_damage = 9.0
            attack_interval = 1.1
            retreat_health_ratio = 0.22
        "brute":
            max_health = 160.0
            wander_speed = 0.8
            chase_speed = 1.8
            notice_distance = 15.0
            hearing_distance = 7.0
            attack_distance = 2.0
            attack_damage = 22.0
            attack_interval = 2.0
            retreat_health_ratio = 0.0
        _:
            archetype = "wanderer"
    health = max_health

func _physics_process(delta: float) -> void:
    if is_dead or get_tree().paused:
        return
    if player == null or not is_instance_valid(player):
        player = get_tree().current_scene.get_node_or_null("Player")
    if player == null or bool(player.get("is_dead")):
        _stop_horizontal(delta)
        velocity.y = -0.5
        move_and_slide()
        return

    attack_timer = maxf(0.0, attack_timer - delta)
    change_timer -= delta
    var distance_to_player := global_position.distance_to(player.global_position)
    var can_see_player := distance_to_player <= notice_distance and _has_line_of_sight()
    var can_hear_player := distance_to_player <= hearing_distance and Input.is_action_pressed("run")

    if can_see_player or can_hear_player:
        target_memory_timer = lose_target_seconds
        target_point = player.global_position
        state = AIState.CHASE
    else:
        target_memory_timer = maxf(0.0, target_memory_timer - delta)
        if target_memory_timer <= 0.0 and state != AIState.PATROL:
            state = AIState.INVESTIGATE
            if global_position.distance_to(target_point) < 1.5:
                state = AIState.PATROL
                _choose_target()

    if retreat_health_ratio > 0.0 and health / max_health <= retreat_health_ratio:
        state = AIState.RETREAT

    match state:
        AIState.CHASE:
            _move_toward_point(target_point, chase_speed, delta)
            if distance_to_player <= attack_distance:
                state = AIState.ATTACK
                attack_windup = 0.22
        AIState.ATTACK:
            _stop_horizontal(delta)
            if distance_to_player > attack_distance * 1.35:
                state = AIState.CHASE
            elif attack_windup > 0.0:
                attack_windup = maxf(0.0, attack_windup - delta)
            elif attack_timer <= 0.0:
                if player.has_method("take_damage"):
                    player.take_damage(attack_damage)
                attack_timer = attack_interval
                state = AIState.CHASE
        AIState.RETREAT:
            if distance_to_player > notice_distance * 1.5:
                state = AIState.PATROL
                _choose_target()
            else:
                var away := global_position - player.global_position
                away.y = 0.0
                if away.length() > 0.01:
                    _move_toward_point(global_position + away.normalized() * 12.0, chase_speed, delta)
                else:
                    _stop_horizontal(delta)
        AIState.INVESTIGATE:
            _move_toward_point(target_point, wander_speed * 1.25, delta)
        AIState.PATROL:
            if change_timer <= 0.0 or global_position.distance_to(target_point) < 1.4:
                _choose_target()
            _move_toward_point(target_point, wander_speed, delta)

    velocity.y = -0.5
    move_and_slide()

func _has_line_of_sight() -> bool:
    if player == null:
        return false
    var from := global_position + Vector3.UP * 1.0
    var to := player.global_position + Vector3.UP * 1.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    query.collision_mask = 1
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player

func _move_toward_point(destination: Vector3, speed: float, delta: float) -> void:
    var flat := destination - global_position
    flat.y = 0.0
    if flat.length() <= 0.2:
        _stop_horizontal(delta)
        return
    var direction := flat.normalized()
    velocity.x = move_toward(velocity.x, direction.x * speed, 7.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * speed, 7.0 * delta)
    var desired_yaw := atan2(-direction.x, -direction.z)
    rotation.y = lerp_angle(rotation.y, desired_yaw, minf(1.0, 5.0 * delta))

func _stop_horizontal(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 7.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 7.0 * delta)

func _choose_target() -> void:
    target_point = Vector3(rng.randf_range(-25.0, 25.0), 0.0, rng.randf_range(-25.0, 25.0))
    change_timer = rng.randf_range(4.0, 8.0)
    state = AIState.PATROL

func take_damage(amount: float) -> void:
    if is_dead or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        is_dead = true
        velocity = Vector3.ZERO
        enemy_died.emit(name)
        queue_free()
    elif player != null:
        target_point = player.global_position
        target_memory_timer = lose_target_seconds
        state = AIState.CHASE
