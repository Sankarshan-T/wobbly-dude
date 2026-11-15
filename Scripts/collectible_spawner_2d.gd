class_name CollectibleSpawner2D
extends Node2D
## Scatters collectables across the walkable path around itself so a level is
## ready to speed-run without hand-placing every pickup.

@export var collectible_scene: PackedScene
@export var spawn_count: int = 12
@export var spawn_radius: float = 560.0
@export var min_player_distance: float = 90.0
@export var min_spacing: float = 72.0

const PathSpawn := preload("res://Scripts/path_spawn_2d.gd")

var _rng := RandomNumberGenerator.new()
var _candidates: Array[Vector2] = []
var _placed: Array[Vector2] = []


func _ready() -> void:
	_rng.randomize()

	# let the tilemap colliders register before we query the physics space
	await get_tree().physics_frame
	await get_tree().physics_frame

	_candidates = PathSpawn.walkable_points(self, global_position, spawn_radius)

	for i in spawn_count:
		_spawn_one()


func _spawn_one() -> void:
	if collectible_scene == null:
		push_warning("CollectibleSpawner2D: no collectible_scene assigned")
		return

	var point: Variant = _pick_point()
	if point == null:
		return

	var collectible: Node2D = collectible_scene.instantiate()
	collectible.global_position = point
	get_parent().add_child(collectible)
	_placed.append(point)


func _pick_point() -> Variant:
	if _candidates.is_empty():
		return null

	var player := get_tree().get_first_node_in_group("player")
	var usable: Array[Vector2] = []

	for point in _candidates:
		if is_instance_valid(player) and point.distance_to(player.global_position) < min_player_distance:
			continue

		var too_close := false
		for placed in _placed:
			if point.distance_to(placed) < min_spacing:
				too_close = true
				break
		if too_close:
			continue

		usable.append(point)

	if usable.is_empty():
		return null
	return usable[_rng.randi() % usable.size()]
