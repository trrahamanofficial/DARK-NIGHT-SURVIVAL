extends Node

const MODE_NAMES := {"story_campaign":"STORY CAMPAIGN","survival":"SURVIVAL MODE","free_explore":"FREE EXPLORE","coop":"CO-OP MODE","nightmare":"NIGHTMARE MODE","custom":"CUSTOM MODE"}
const DIFFICULTY_NAMES := {"easy":"EASY","normal":"NORMAL","hard":"HARD","nightmare":"NIGHTMARE","dynamic":"DYNAMIC"}
const DIFFICULTY := {
 "easy":{"damage":0.7,"detection":0.8,"health":0.9,"resources":1.3},
 "normal":{"damage":1.0,"detection":1.0,"health":1.0,"resources":1.0},
 "hard":{"damage":1.35,"detection":1.2,"health":1.2,"resources":0.8},
 "nightmare":{"damage":1.8,"detection":1.45,"health":1.5,"resources":0.6},
 "dynamic":{"damage":1.0,"detection":1.0,"health":1.0,"resources":1.0}
}
var current_mode := "story_campaign"
var current_difficulty := "normal"
var custom_threat := 1.0
var custom_resources := 1.0

func _ready() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://game_mode.cfg") == OK:
  var saved_mode := str(cfg.get_value("game","mode","story_campaign"))
  var saved_difficulty := str(cfg.get_value("game","difficulty","normal"))
  if MODE_NAMES.has(saved_mode): current_mode = saved_mode
  if DIFFICULTY_NAMES.has(saved_difficulty): current_difficulty = saved_difficulty
  custom_threat = clampf(float(cfg.get_value("custom","threat",1.0)),0.5,2.0)
  custom_resources = clampf(float(cfg.get_value("custom","resources",1.0)),0.5,2.0)
 if current_mode == "coop": current_mode = "story_campaign"

func get_mode_name() -> String:
 return get_mode_name_for(current_mode)

func get_mode_name_for(mode_id: String) -> String:
 return str(MODE_NAMES.get(mode_id,"UNKNOWN MODE"))

func get_difficulty_name() -> String:
 return get_difficulty_name_for(current_difficulty)

func get_difficulty_name_for(difficulty_id: String) -> String:
 return str(DIFFICULTY_NAMES.get(difficulty_id,"NORMAL"))

func set_mode(mode_id: String) -> bool:
 if not MODE_NAMES.has(mode_id) or mode_id == "coop": return false
 current_mode = mode_id
 return _save()

func set_difficulty(difficulty_id: String) -> bool:
 if not DIFFICULTY.has(difficulty_id): return false
 current_difficulty = difficulty_id
 return _save()

func set_custom_rules(threat: float, resources: float) -> bool:
 custom_threat = clampf(threat,0.5,2.0)
 custom_resources = clampf(resources,0.5,2.0)
 return _save()

func get_enemy_damage_multiplier(player_health: float = 100.0) -> float:
 var value := float(DIFFICULTY[current_difficulty]["damage"])
 if current_mode == "custom": value = custom_threat
 elif current_difficulty == "dynamic":
  value = 0.82 if player_health < 35.0 else (1.18 if player_health > 80.0 else 1.0)
 if current_mode == "nightmare": value *= 1.35
 return value

func get_enemy_detection_multiplier() -> float:
 var value := float(DIFFICULTY[current_difficulty]["detection"])
 if current_mode == "custom": value = lerpf(0.75,1.5,(custom_threat-0.5)/1.5)
 elif current_difficulty == "dynamic": value = 1.0
 if current_mode == "nightmare": value *= 1.2
 return value

func get_enemy_health_multiplier() -> float:
 var value := float(DIFFICULTY[current_difficulty]["health"])
 if current_mode == "custom": value = custom_threat
 if current_mode == "nightmare": value *= 1.2
 return value

func scale_resource_amount(amount: int) -> int:
 var multiplier := custom_resources if current_mode == "custom" else float(DIFFICULTY[current_difficulty]["resources"])
 return maxi(1, roundi(float(amount) * multiplier))

func _save() -> bool:
 var cfg := ConfigFile.new()
 cfg.set_value("game","mode",current_mode)
 cfg.set_value("game","difficulty",current_difficulty)
 cfg.set_value("custom","threat",custom_threat)
 cfg.set_value("custom","resources",custom_resources)
 return cfg.save("user://game_mode.cfg") == OK
