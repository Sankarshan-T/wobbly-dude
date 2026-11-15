extends CharacterBody2D

const SPEED = 200.0

@export_group("Combat")
@export var attack_damage: int = 12
@export var attack_range: float = 46.0
@export var attack_arc: float = 120.0
@export var attack_cooldown: float = 0.35
@export var knockback_force: float = 220.0

@export_group("Survival")
@export var invulnerability_time: float = 1.0

@onready var shadow: Sprite2D = $shadow
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN
var current_direction := Vector2.ZERO

const WALK_BOB_AMOUNT := 3.0
const WALK_BOB_SPEED := 10.0

const IDLE_BOB_AMOUNT := 0.5
const IDLE_BOB_SPEED := 5.5

var bob_time := 0.0
var sprite_start_position := Vector2.ZERO

const SHADOW_SMOOTHNESS := 4.0
const SHADOW_DISTANCE := 15.0
const SHADOW_BASE_OFFSET := Vector2(0, 5)

var shadow_offset := Vector2.ZERO

var _sprite_base_scale := Vector2.ONE
var _attack_timer := 0.0
var _invulnerable_timer := 0.0
var _knockback := Vector2.ZERO
var _is_dead := false


func _ready() -> void:
	add_to_group("player")
	shadow.position = SHADOW_BASE_OFFSET
	sprite_start_position = sprite.position
	_sprite_base_scale = sprite.scale
	GameState.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if _is_dead:
		return

	var target_offset := Vector2.ZERO

	if current_direction != Vector2.ZERO:
		target_offset = -current_direction * SHADOW_DISTANCE

	shadow_offset = shadow_offset.lerp(
		target_offset,
		1.0 - exp(-SHADOW_SMOOTHNESS * delta)
	)

	shadow.position = SHADOW_BASE_OFFSET + shadow_offset



	var bob_amount: float
	var bob_speed: float

	if current_direction != Vector2.ZERO:
		bob_amount = WALK_BOB_AMOUNT
		bob_speed = WALK_BOB_SPEED
	else:
		bob_amount = IDLE_BOB_AMOUNT
		bob_speed = IDLE_BOB_SPEED

	bob_time += delta * bob_speed

	sprite.position.y = (
		sprite_start_position.y
		+ sin(bob_time) * bob_amount
	)


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_update_invulnerability(delta)

	_knockback = _knockback.lerp(Vector2.ZERO, 1.0 - exp(-9.0 * delta))

	if _is_dead:
		velocity = _knockback
		move_and_slide()
		return

	var direction := Input.get_vector(
		"left",
		"right",
		"forward",
        "backward"
	)

	current_direction = direction

	if Input.is_action_pressed("speed"):
		velocity = direction * SPEED * 2.3
	else:
		velocity = direction * SPEED

	velocity += _knockback

	move_and_slide()

	update_animation(direction)

	if Input.is_action_just_pressed("attack"):
		attack()


func update_animation(direction: Vector2) -> void:

	if direction != Vector2.ZERO:
		last_direction = direction
		sprite.play("active")
	else:
		sprite.play("idle")

	if abs(last_direction.x) > abs(last_direction.y):
		sprite.flip_h = last_direction.x < 0
	else:
		sprite.flip_h = false


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_timer > 0.0:
		_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
		sprite.modulate.a = 0.35 if int(_invulnerable_timer * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


func attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown

	# small lunge for feedback
	var tween := create_tween()
	tween.tween_property(sprite, "scale", _sprite_base_scale * 1.15, 0.06)
	tween.tween_property(sprite, "scale", _sprite_base_scale, 0.12)

	var facing := last_direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	var half_arc := deg_to_rad(attack_arc) * 0.5

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() > attack_range + 12.0:
			continue
		if offset != Vector2.ZERO and absf(facing.angle_to(offset.normalized())) > half_arc:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage, global_position)


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dead or _invulnerable_timer > 0.0:
		return

	GameState.take_damage(amount)
	_invulnerable_timer = invulnerability_time

	if source_position != Vector2.ZERO:
		_knockback = (global_position - source_position).normalized() * knockback_force


func _on_player_died() -> void:
	if _is_dead:
		return
	_is_dead = true

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await tween.finished
	await get_tree().create_timer(0.8).timeout

	GameState.reset_state()
	SceneManager.change_scene(get_tree().current_scene.scene_file_path)
