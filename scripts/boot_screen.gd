extends Control

const GAME_SCENE := "res://scenes/main.tscn"

var progress_bar: ProgressBar
var status_label: Label

func _ready() -> void:
    _build_screen()
    await get_tree().process_frame
    _load_game_scene()

func _build_screen() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := ColorRect.new()
    background.color = Color(0.006, 0.009, 0.018, 1.0)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var stack := VBoxContainer.new()
    stack.custom_minimum_size = Vector2(560, 220)
    stack.add_theme_constant_override("separation", 22)
    center.add_child(stack)

    var title := Label.new()
    title.text = "DARK NIGHT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))
    stack.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "SURVIVAL"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", Color(0.58, 0.68, 0.82))
    stack.add_child(subtitle)

    status_label = Label.new()
    status_label.text = "PREPARING THE NIGHT..."
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
    stack.add_child(status_label)

    progress_bar = ProgressBar.new()
    progress_bar.custom_minimum_size = Vector2(480, 18)
    progress_bar.min_value = 0
    progress_bar.max_value = 100
    progress_bar.value = 0
    progress_bar.show_percentage = false
    stack.add_child(progress_bar)

func _load_game_scene() -> void:
    var request_error := ResourceLoader.load_threaded_request(GAME_SCENE, "PackedScene", true)
    if request_error != OK:
        _show_error("Unable to start game loading. Error: " + error_string(request_error))
        return

    while true:
        var progress: Array = []
        var state := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
        if not progress.is_empty():
            progress_bar.value = clampf(float(progress[0]) * 100.0, 0.0, 100.0)
        if state == ResourceLoader.THREAD_LOAD_LOADED:
            break
        if state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _show_error("Game files could not be loaded. Please report this screen.")
            return
        await get_tree().process_frame

    status_label.text = "ENTERING THE DARK FOREST..."
    progress_bar.value = 100
    var packed_scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
    if packed_scene == null:
        _show_error("The game scene is missing or damaged.")
        return
    await get_tree().process_frame
    var change_error := get_tree().change_scene_to_packed(packed_scene)
    if change_error != OK:
        _show_error("Unable to open the game scene. Error: " + error_string(change_error))

func _show_error(message: String) -> void:
    status_label.text = message
    status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
