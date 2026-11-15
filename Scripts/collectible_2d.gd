class_name Collectible2D
extends Area2D
## Floating scrap pickup. Grabbed by touching it with the player.

signal collected

@export var amount: int = 1
@export var completion_flag: String = ""
@export var gem_color: Color = Color(1.0, 0.83, 0.22)
@export var bob_amount: float = 3.0
@export var bob_speed: float = 3.0

var _taken := false
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)
	_base_y = position.y


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	position.y = _base_y + sin(_t * bob_speed) * bob_amount


func _draw() -> void:
	var r := 8.0
	var glow := gem_color
	glow.a = 0.22
	draw_circle(Vector2.ZERO, r * 1.9, glow)

	var points := PackedVector2Array([
		Vector2(0, -r),
		Vector2(r * 0.75, 0),
		Vector2(0, r),
		Vector2(-r * 0.75, 0),
	])
	draw_colored_polygon(points, gem_color)

	points.append(points[0])
	draw_polyline(points, Color(1, 1, 1, 0.85), 1.5)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return

	_taken = true
	set_process(false)

	GameState.add_collectibles(amount)
	if completion_flag != "":
		GameState.set_flag(completion_flag, true)
	collected.emit()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "position:y", position.y - 24.0, 0.25)
	tween.chain().tween_callback(queue_free)
