extends Control

signal vector_changed(value: Vector2)

@export var radius := 66.0
@export var deadzone := 0.12

var active_touch := -1
var stick_vector := Vector2.ZERO
var knob_position := Vector2.ZERO

func _ready() -> void:
    custom_minimum_size = Vector2(radius * 2.5, radius * 2.5)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var center := size * 0.5
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1 and event.position.distance_to(center) <= radius * 1.7:
            active_touch = event.index
            _update_stick(event.position - center)
            accept_event()
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            _set_vector(Vector2.ZERO)
            accept_event()
    elif event is InputEventScreenDrag and event.index == active_touch:
        _update_stick(event.position - center)
        accept_event()

func _update_stick(offset: Vector2) -> void:
    var limited := offset.limit_length(radius)
    knob_position = limited
    var next_vector := Vector2(limited.x / radius, limited.y / radius)
    if next_vector.length() < deadzone:
        next_vector = Vector2.ZERO
    _set_vector(next_vector)
    queue_redraw()

func _set_vector(value: Vector2) -> void:
    stick_vector = value
    vector_changed.emit(stick_vector)

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, radius, Color(0.025, 0.04, 0.07, 0.48))
    draw_arc(center, radius, 0.0, TAU, 48, Color(0.55, 0.68, 0.82, 0.72), 2.0, true)
    draw_circle(center + knob_position, radius * 0.43, Color(0.45, 0.62, 0.82, 0.78))
    draw_arc(center + knob_position, radius * 0.43, 0.0, TAU, 36, Color(0.82, 0.9, 1.0, 0.9), 2.0, true)
