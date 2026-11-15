extends CharacterBody2D

const SPEED = 200.0

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


func _ready() -> void:
	shadow.position = SHADOW_BASE_OFFSET
	sprite_start_position = sprite.position


func _process(delta: float) -> void:
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


func _physics_process(_delta: float) -> void:

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

	move_and_slide()

	update_animation(direction)


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
