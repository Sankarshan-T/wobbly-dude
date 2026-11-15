extends CharacterBody3D

const SPEED = 5.5
const MULT_SPEED = 2.5
const JUMP_VELOCITY = 6.5
const MOUSE_SENSITIVITY = 0.003

@export_group("Combat")
@export var attack_damage: int = 15
@export var attack_range: float = 4.0
@export var attack_arc: float = 100.0
@export var attack_cooldown: float = 0.4

@export_group("Survival")
@export var invulnerability_time: float = 1.0

@onready var camera: Camera3D = $Camera3D

var _attack_timer := 0.0
var _invulnerable_timer := 0.0
var _is_dead := false


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			attack()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if Input.is_action_pressed("speed"):
			velocity.x = direction.x * SPEED * MULT_SPEED
			velocity.z = direction.z * SPEED * MULT_SPEED
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func attack() -> void:
	if _attack_timer > 0.0 or _is_dead:
		return
	_attack_timer = attack_cooldown

	var forward := -global_transform.basis.z
	var half_arc := deg_to_rad(attack_arc) * 0.5

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var offset: Vector3 = enemy.global_position - global_position
		var flat := Vector3(offset.x, 0, offset.z)
		if flat.length() > attack_range + 1.0:
			continue
		if flat != Vector3.ZERO and absf(forward.angle_to(flat.normalized())) > half_arc:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage, global_position)


func take_damage(amount: int, _source_position: Vector3 = Vector3.ZERO) -> void:
	if _is_dead or _invulnerable_timer > 0.0:
		return
	GameState.take_damage(amount)
	_invulnerable_timer = invulnerability_time


func _on_player_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(1.0).timeout

	GameState.reset_state()
	SceneManager.change_scene(get_tree().current_scene.scene_file_path)
