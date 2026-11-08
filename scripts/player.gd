extends CharacterBody3D

@export var walk_speed := 4.2
@export var run_speed := 6.8
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0
var look_pitch := 0.0
var flashlight_on := true
@onready var head: Node3D = $Head
@onready var lamp: SpotLight3D = $Head/Camera3D/Flashlight

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        look_pitch = clamp(look_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-82), deg_to_rad(82))
        head.rotation.x = look_pitch
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
        flashlight_on = not flashlight_on
        lamp.visible = flashlight_on

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed := run_speed if Input.is_action_pressed("run") else walk_speed
    velocity.x = move_toward(velocity.x, direction.x * speed, 18.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * speed, 18.0 * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()
