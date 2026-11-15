extends Node

signal health_changed(new_health: int, max_health: int)
signal collectible_count_changed(new_count: int)
signal player_died
signal stalker_activated

@export var max_health: int = 100
var current_health: int = 100
var collectibles: int = 0

# The pursuer that hunts the player across the 3D and 2D worlds. Once it has
# locked on it stays active through scene changes, so it "follows" you into the
# next world even though it is a different node there.
var stalker_active: bool = false

var flags: Dictionary = {}


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		player_died.emit()


func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)


func add_collectibles(amount: int = 1) -> void:
	collectibles += amount
	collectible_count_changed.emit(collectibles)


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)


## Start (or keep) the pursuer hunting the player. Safe to call repeatedly.
func activate_stalker() -> void:
	if stalker_active:
		return
	stalker_active = true
	stalker_activated.emit()


func reset_state() -> void:
	current_health = max_health
	collectibles = 0
	flags.clear()
	health_changed.emit(current_health, max_health)
	collectible_count_changed.emit(collectibles)
