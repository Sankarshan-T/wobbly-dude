class_name Enemy2D
extends CharacterBody2D
## Hostile drone for the 2D levels.
## Our hostile ron, also deals contact damage, it works 
## We make it wander around it;s spwan point if the player is far
## And chases the player once we enter 
## The player can damage and kill the drone using his mouse
## Also drops scals(collect) but it's a lil buggy

signal died(enemy: Enemy2D)
signal health_changed(current_health: int, max_health: int)

enum State { PATROL, CHASE, DEAD }

@export_group("Stats")
@export var max_health: int = 30
@export var move_speed: float = 55.0
@export var chase_speed: float = 100.0

@export_group("Combat")
@export var contact_damage: int = 10
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 0.9
@export var knockback_force: float = 260.0
@export var knockback_decay: float = 9.0
@export var stun_time: float = 0.18

@export_group("Detection")
@export var detect_radius: float = 200.0
@export var lose_radius: float = 340.0
## Relentless pursuer mode: ignore detection range and never give up the chase.
@export var always_aggro: bool = false

@export_group("Patrol")
@export var patrol_enabled: bool = true
@export var patrol_radius: float = 90.0
@export var patrol_wait_time: float = 1.1

@export_group("Rewards")
@export var collectibles_on_death: int = 1
@export var completion_flag_on_death: String = ""

@export_group("Visuals")
@export var tint: Color = Color(1.0, 0.55, 0.55)
@export var bob_amount: float = 2.5
@export var bob_speed: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Sprite2D = $shadow
@onready var health_bar: ProgressBar = $HealthBar

var state: State = State.PATROL
var current_health: int = 0

var _player: Node2D
var _home: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_wait: float = 0.0
var _attack_timer: float = 0.0
var _stun_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _sprite_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	_home = global_position
	_patrol_target = _home
	_sprite_start = sprite.position
	sprite.modulate = tint
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = max_health
		health_bar.show_percentage = false
		health_bar.hide()
	_pick_patrol_target()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_stun_timer = maxf(_stun_timer - delta, 0.0)
	_bob_time += delta * bob_speed

	_resolve_player()

	var to_player := Vector2.ZERO
	var distance := INF
	if is_instance_valid(_player):
		to_player = _player.global_position - global_position
		distance = to_player.length()

	var desired := Vector2.ZERO

	if _stun_timer > 0.0:
		desired = Vector2.ZERO
	elif always_aggro and is_instance_valid(_player):
		if state != State.CHASE:
			state = State.CHASE
			GameState.activate_stalker()
		if distance > 0.0:
			desired = to_player / distance * chase_speed
		if distance <= attack_range:
			_try_contact_attack()
	else:
		match state:
			State.PATROL:
				desired = _patrol_velocity(delta)
				if distance <= detect_radius:
					state = State.CHASE
					GameState.activate_stalker()
			State.CHASE:
				if distance > 0.0:
					desired = to_player / distance * chase_speed
				if distance <= attack_range:
					_try_contact_attack()
				if distance > lose_radius:
					state = State.PATROL
					_pick_patrol_target()

	velocity = desired + _knockback
	_knockback = _knockback.lerp(Vector2.ZERO, 1.0 - exp(-knockback_decay * delta))

	move_and_slide()
	_update_facing()
	_update_bob()
	_update_animation()


func _resolve_player() -> void:
	if is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player")


func _patrol_velocity(delta: float) -> Vector2:
	if not patrol_enabled:
		return Vector2.ZERO
	if _patrol_wait > 0.0:
		_patrol_wait -= delta
		return Vector2.ZERO

	var to_target := _patrol_target - global_position
	if to_target.length() < 8.0:
		_patrol_wait = patrol_wait_time
		_pick_patrol_target()
		return Vector2.ZERO

	return to_target.normalized() * move_speed


func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var radius := randf() * patrol_radius
	_patrol_target = _home + Vector2(cos(angle), sin(angle)) * radius


func _try_contact_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		_player.take_damage(contact_damage, global_position)


func _update_facing() -> void:
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0


func _update_bob() -> void:
	sprite.position.y = _sprite_start.y + sin(_bob_time) * bob_amount


func _update_animation() -> void:
	var wanted := "active" if velocity.length() > 1.0 else "idle"
	if sprite.animation != wanted:
		sprite.play(wanted)


## Damage the enemy. [param source_position] is used to push it away from the hit.
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if health_bar:
		health_bar.value = current_health
		health_bar.show()

	_stun_timer = stun_time
	if source_position != Vector2.ZERO:
		_knockback = (global_position - source_position).normalized() * knockback_force

	_flash()

	if current_health <= 0:
		die()


func _flash() -> void:
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", tint, 0.15)


func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	remove_from_group("enemies")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	if health_bar:
		health_bar.hide()

	if collectibles_on_death > 0:
		GameState.add_collectibles(collectibles_on_death)
	if completion_flag_on_death != "":
		GameState.set_flag(completion_flag_on_death, true)

	died.emit(self)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	if shadow:
		tween.tween_property(shadow, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
