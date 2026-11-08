extends Node

const SAVE_DIR := "user://saves"
const SAVE_VERSION := 1
const SLOT_COUNT := 3

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func _slot_path(slot: int) -> String:
    return "%s/slot_%d.json" % [SAVE_DIR, slot]

func _valid_slot(slot: int) -> bool:
    return slot >= 1 and slot <= SLOT_COUNT

func save_slot(slot: int, payload: Dictionary) -> bool:
    if not _valid_slot(slot):
        return false
    var data := {
        "save_version": SAVE_VERSION,
        "saved_at_unix": int(Time.get_unix_time_from_system()),
        "payload": payload
    }
    var path := _slot_path(slot)
    var temp_path := path + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager: could not open temporary save file.")
        return false
    file.store_string(JSON.stringify(data, "\t"))
    file.flush()
    file.close()
    var absolute_temp := ProjectSettings.globalize_path(temp_path)
    var absolute_path := ProjectSettings.globalize_path(path)
    if FileAccess.file_exists(path):
        var backup_path := path + ".bak"
        var absolute_backup := ProjectSettings.globalize_path(backup_path)
        if FileAccess.file_exists(backup_path):
            DirAccess.remove_absolute(absolute_backup)
        var backup_error := DirAccess.rename_absolute(absolute_path, absolute_backup)
        if backup_error != OK:
            DirAccess.remove_absolute(absolute_temp)
            push_error("SaveManager: could not rotate previous save.")
            return false
    var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_path)
    if rename_error != OK:
        push_error("SaveManager: could not finalize save file.")
        return false
    return true

func load_slot(slot: int) -> Dictionary:
    if not _valid_slot(slot):
        return {}
    var path := _slot_path(slot)
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    if int(parsed.get("save_version", -1)) != SAVE_VERSION:
        push_warning("SaveManager: save version is not supported.")
        return {}
    var payload: Variant = parsed.get("payload", {})
    return payload if typeof(payload) == TYPE_DICTIONARY else {}

func slot_exists(slot: int) -> bool:
    return _valid_slot(slot) and FileAccess.file_exists(_slot_path(slot))

func delete_slot(slot: int) -> bool:
    if not _valid_slot(slot):
        return false
    var path := _slot_path(slot)
    if not FileAccess.file_exists(path):
        return true
    return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func get_slot_summary(slot: int) -> Dictionary:
    if not slot_exists(slot):
        return {"exists": false, "label": "Empty"}
    var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
    if file == null:
        return {"exists": false, "label": "Unreadable"}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("save_version", -1)) != SAVE_VERSION:
        return {"exists": true, "label": "Incompatible save"}
    var stamp := int(parsed.get("saved_at_unix", 0))
    return {"exists": true, "label": Time.get_datetime_string_from_unix_time(stamp, true)}
