extends Node

signal campaign_updated(mission_title: String, objective_text: String, progress_text: String)
signal campaign_completed

const MISSIONS := [
    {"id": "reach_radio", "title": "CHAPTER 1 — THE SILENT FOREST", "objective": "Follow the trail and reach the abandoned radio.", "target": 1},
    {"id": "evidence", "title": "CHAPTER 2 — LOST SIGNAL", "objective": "Find all three missing radio evidence pieces.", "target": 3},
    {"id": "signal_tower", "title": "CHAPTER 3 — THE LAST TRANSMISSION", "objective": "Reach the old signal tower and restore contact.", "target": 1},
    {"id": "extraction", "title": "CHAPTER 4 — GET OUT ALIVE", "objective": "Reach the extraction clearing.", "target": 1}
]

var mission_index := 0
var objective_count := 0
var completed_objectives: Array[String] = []
var checkpoint_position := Vector3.ZERO
var checkpoint_health := 100.0
var is_complete := false

func _ready() -> void:
    _emit_update()

func begin_if_new() -> void:
    if mission_index == 0 and objective_count == 0 and completed_objectives.is_empty() and not is_complete:
        _emit_update()

func get_current_mission() -> Dictionary:
    if is_complete or mission_index >= MISSIONS.size():
        return {"id": "complete", "title": "CAMPAIGN COMPLETE", "objective": "You escaped the Dark Forest.", "target": 0}
    return MISSIONS[mission_index]

func get_mission_title() -> String:
    return str(get_current_mission().get("title", "DARK NIGHT"))

func get_objective_text() -> String:
    return str(get_current_mission().get("objective", ""))

func get_progress_text() -> String:
    if is_complete:
        return "ALL CHAPTERS COMPLETE"
    var target := int(get_current_mission().get("target", 1))
    return "OBJECTIVE %d / %d" % [objective_count, target]

func complete_objective(objective_id: String) -> bool:
    if is_complete:
        return false
    var current_id := str(get_current_mission().get("id", ""))
    if objective_id != current_id:
        return false
    if objective_id == "evidence":
        objective_count += 1
    else:
        objective_count = 1
        if not completed_objectives.has(objective_id):
            completed_objectives.append(objective_id)
    var target := int(get_current_mission().get("target", 1))
    if objective_count >= target:
        mission_index += 1
        objective_count = 0
        if mission_index >= MISSIONS.size():
            is_complete = true
            campaign_completed.emit()
    _emit_update()
    return true

func is_objective_done(objective_id: String) -> bool:
    return completed_objectives.has(objective_id)

func mark_evidence_found(evidence_id: String) -> bool:
    if is_complete or str(get_current_mission().get("id", "")) != "evidence":
        return false
    if completed_objectives.has(evidence_id):
        return false
    completed_objectives.append(evidence_id)
    return complete_objective("evidence")

func set_checkpoint(position_3d: Vector3, health: float) -> void:
    checkpoint_position = position_3d
    checkpoint_health = clampf(health, 1.0, 100.0)

func get_save_data() -> Dictionary:
    return {
        "mission_index": mission_index,
        "objective_count": objective_count,
        "completed_objectives": completed_objectives.duplicate(),
        "checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z],
        "checkpoint_health": checkpoint_health,
        "is_complete": is_complete
    }

func load_save_data(data: Dictionary) -> void:
    mission_index = clampi(int(data.get("mission_index", 0)), 0, MISSIONS.size())
    objective_count = maxi(0, int(data.get("objective_count", 0)))
    completed_objectives.clear()
    var saved: Variant = data.get("completed_objectives", [])
    if typeof(saved) == TYPE_ARRAY:
        for item in saved:
            completed_objectives.append(str(item))
    var point: Variant = data.get("checkpoint_position", [0.0, 0.0, 0.0])
    if typeof(point) == TYPE_ARRAY and point.size() == 3:
        checkpoint_position = Vector3(float(point[0]), float(point[1]), float(point[2]))
    checkpoint_health = clampf(float(data.get("checkpoint_health", 100.0)), 1.0, 100.0)
    is_complete = bool(data.get("is_complete", false)) or mission_index >= MISSIONS.size()
    _emit_update()

func _emit_update() -> void:
    campaign_updated.emit(get_mission_title(), get_objective_text(), get_progress_text())
