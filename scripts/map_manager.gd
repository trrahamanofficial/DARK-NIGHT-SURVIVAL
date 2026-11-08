extends Node

const MAPS := {
    "forest": {"name": "DARK FOREST", "description": "A fog-covered forest with a lost radio signal."},
    "hospital": {"name": "ABANDONED HOSPITAL", "description": "Silent wards, damaged rooms and cold emergency lights."},
    "village": {"name": "OLD VILLAGE", "description": "An abandoned settlement with huts, a village square and church."},
    "bunker": {"name": "UNDERGROUND BUNKER", "description": "A sealed underground facility with reinforced corridors."}
}

var current_map_id := "forest"

func _ready() -> void:
    var config := ConfigFile.new()
    if config.load("user://map_selection.cfg") == OK:
        var saved_id := str(config.get_value("maps", "selected", "forest"))
        if MAPS.has(saved_id):
            current_map_id = saved_id

func get_map_name(map_id: String) -> String:
    if MAPS.has(map_id):
        return str(MAPS[map_id]["name"])
    return "UNKNOWN LOCATION"

func get_map_description(map_id: String) -> String:
    if MAPS.has(map_id):
        return str(MAPS[map_id]["description"])
    return ""

func select_map(map_id: String) -> bool:
    if not MAPS.has(map_id):
        return false
    current_map_id = map_id
    var config := ConfigFile.new()
    config.set_value("maps", "selected", current_map_id)
    return config.save("user://map_selection.cfg") == OK
