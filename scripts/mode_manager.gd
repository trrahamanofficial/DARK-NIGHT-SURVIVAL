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

func _ready() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://game_mode.cfg") == OK:
  var saved_mode := str(cfg.get_value("game","mode","story_campaign"))
  var saved_difficulty := str(cfg.get_value("game","difficulty","normal"))
  if MODE_NAMES.has(saved_mode): current_mode = saved_mode
  if DIFFICULTY_NAMES.has(saved_difficulty): current_difficulty = saved_difficulty
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

func get_enemy_damage_multiplier(player_health: float = 100.0) -> float:
 var value := float(DIFFICULTY[current_difficulty]["damage"])
 if current_difficulty == "dynamic":
  value = 0.82 if player_health < 35.0 else (1.18 if player_health > 80.0 else 1.0)
 if current_mode == "nightmare": value *= 1.35
 return value

func get_enemy_detection_multiplier() -> float:
 var value := float(DIFFICULTY[current_difficulty]["detection"])
 if current_difficulty == "dynamic": value = 1.0
 if current_mode == "nightmare": value *= 1.2
 return value

func get_enemy_health_multiplier() -> float:
 var value := float(DIFFICULTY[current_difficulty]["health"])
 if current_mode == "nightmare": value *= 1.2
 return value

func scale_resource_amount(amount: int) -> int:
 return maxi(1, roundi(float(amount) * float(DIFFICULTY[current_difficulty]["resources"])))

func _save() -> bool:
 var cfg := ConfigFile.new()
 cfg.set_value("game","mode",current_mode)
 cfg.set_value("game","difficulty",current_difficulty)
 return cfg.save("user://game_mode.cfg") == OK
