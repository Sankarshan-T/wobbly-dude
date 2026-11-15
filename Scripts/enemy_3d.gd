class_name Enemy3D
extends CharacterBody3D
## We stalk the player :hehehe
## Once the enemy sees(in the enemy sight) the player in sight, It locks the  stalker from the game state and then we fllow enemy
### "Once the enemy sees the player" -By this I mean always!

signal died(enemy: Enemy3D)
signal health_changed(current_health: int, max_health: int)

@export_group("Stats")
@export var max_health: int = 40
@export var speed: float = 4.5
@export var acceleration: float = 7.0
@export var hover_height: float = 1.8

@export_group("Combat")
@export var contact_damage: int = 8
@export var attack_range: float = 2.4
@export var attack_cooldown: float = 1.0
@export var knockback_force: float = 3.5

@export_group("Detection")
@export var detect_radius: float = 80.0

@export_group("Visuals")
@export var bob_amount: float = 0.15
@export var bob_speed: float = 2.5

@onready var mesh: MeshInstance3D = $MeshInstance3D

var current_health: int = 0

var _player: Node3D
var _attack_timer: float = 0.0
var _stun_timer: float = 0.0
var _bob_time: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _mesh_start: Vector3 = Vector3.ZERO
var _dead := false


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_mesh_start = mesh.position
	_resolve_player()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_stun_timer = maxf(_stun_timer - delta, 0.0)
	_bob_time += delta * bob_speed
	_knockback = _knockback.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))

	_resolve_player()

	if not is_instance_valid(_player):
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	if to_player.length() <= detect_radius:
		GameState.activate_stalker()

	var target := _player.global_position + Vector3(0, hover_height, 0)
	var to_target := target - global_position
	var distance := to_target.length()

	var desired := Vector3.ZERO
	if _stun_timer <= 0.0 and distance > 0.05:
		desired = to_target / distance * speed

	velocity = velocity.move_toward(desired + _knockback, acceleration * delta)
	move_and_slide()

	var flat := Vector3(_player.global_position.x - global_position.x, 0, _player.global_position.z - global_position.z)
	if flat.length_squared() > 0.001:
		look_at(global_position + flat, Vector3.UP)

	mesh.position = _mesh_start + Vector3(0, sin(_bob_time) * bob_amount, 0)

	if distance <= attack_range:
		_try_contact_attack()


func _resolve_player() -> void:
	if is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player")


func _try_contact_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		_player.take_damage(contact_damage, global_position)


func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	_stun_timer = 0.2
	if source_position != Vector3.ZERO:
		var away := (global_position - source_position)
		away.y = 0.0
		if away.length_squared() > 0.001:
			_knockback = away.normalized() * knockback_force

	_flash()

	if current_health <= 0:
		die()


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.35, 1.35, 1.35), 0.06)
	tween.tween_property(mesh, "scale", Vector3.ONE, 0.15)


func die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("enemies")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	died.emit(self)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(mesh, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
