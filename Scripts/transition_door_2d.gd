class_name TransitionDoor2D
extends Area2D

@export_file("*.tscn") var target_scene: String = ""

@export_group("Lock Conditions")
@export var required_flag: String = ""
@export var required_collectibles: int = 0

@export_group("Rewards & Visuals")
@export var completion_flag: String = ""

@onready var locked_sprite: Sprite2D = $StaticBody2D/DoorLocked
@onready var unlocked_sprite: Sprite2D = $StaticBody2D/DoorClosed

var triggered: bool = false
var is_unlocked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_lock_status()


func _update_lock_status() -> void:
	var has_flag_condition = (required_flag == "" or GameState.has_flag(required_flag))
	var has_collectible_condition = (required_collectibles <= 0 or GameState.collectibles >= required_collectibles)

	if has_flag_condition and has_collectible_condition:
		is_unlocked = true
		if locked_sprite:
			locked_sprite.hide()
		if unlocked_sprite:
			unlocked_sprite.show()
	else:
		is_unlocked = false
		if locked_sprite:
			locked_sprite.show()
		if unlocked_sprite:
			unlocked_sprite.hide()


func _on_body_entered(body: Node2D) -> void:
	if triggered or target_scene == "":
		return

	_update_lock_status()

	if not is_unlocked:
		print("Door locked!")
		return

	if body is CharacterBody2D:
		triggered = true
		body.set_physics_process(false)

		if completion_flag != "":
			GameState.set_flag(completion_flag, true)

		# the pursuer follows the player through the gate
		GameState.activate_stalker()
		SceneManager.change_scene(target_scene)
