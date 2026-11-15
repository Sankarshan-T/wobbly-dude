class_name TransitionDoor3D
extends Area3D

@export_file("*.tscn") var target_scene: String = ""
@export var required_flag: String = ""

@export var open_angle: float = 65.0


var triggered: bool = false
var is_unlocked: bool = false
var is_open: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_lock_status()


func _update_lock_status() -> void:
	if required_flag == "" or GameState.has_flag(required_flag):
		is_unlocked = true
		if not is_open:
			_open_door()
	else:
		is_unlocked = false


func _open_door() -> void:
	is_open = true

func _on_body_entered(body: Node3D) -> void:
	if triggered or target_scene == "":
		return

	_update_lock_status()

	if not is_unlocked:
		print("this door is currently locked! :(")
		return

	if body is CharacterBody3D:
		triggered = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		body.set_physics_process(false)
		# the pursuer follows the player through the gate
		GameState.activate_stalker()
		SceneManager.change_scene(target_scene)
