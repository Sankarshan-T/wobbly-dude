class_name EnemySpawner2D
extends Node2D
## Drops enemies onto the walkable path around itself.
##
## Drop one of these into a level and assign [member enemy_scene]. It also
## tops enemies back up over time so a level never fully empties out.
##
## If the player is being pursued ([member GameState.stalker_active]) and a
## [member stalker_scene] is set, one relentless chaser is spawned on the path
## near the player so the pursuer "follows" them into the 2D world.

@export var enemy_scene: PackedScene
@export var spawn_count: int = 6
@export var spawn_radius: float = 460.0
@export var min_player_distance: float = 140.0
@export var respawn_interval: float = 8.0
@export var max_alive: int = 6

@export_group("Stalker")
@export var stalker_scene: PackedScene
@export var spawn_stalker_if_active: bool = true
@export var stalker_min_distance: float = 200.0
@export var stalker_max_distance: float = 380.0

const PathSpawn := preload("res://Scripts/path_spawn_2d.gd")

var _rng := RandomNumberGenerator.new()
var _candidates: Array[Vector2] = []


func _ready() -> void:
	_rng.randomize()

	# let the tilemap colliders register before we query the physics space
	await get_tree().physics_frame
	await get_tree().physics_frame

	_candidates = PathSpawn.walkable_points(self, global_position, spawn_radius)

	for i in spawn_count:
		_spawn_one()

	if GameState.stalker_active and spawn_stalker_if_active:
		_spawn_stalker()

	if respawn_interval > 0.0:
		var timer := Timer.new()
		timer.wait_time = respawn_interval
		timer.timeout.connect(_on_respawn)
		add_child(timer)
		timer.start()


func _on_respawn() -> void:
	if get_tree().get_nodes_in_group("enemies").size() < max_alive:
		_spawn_one()


func _spawn_one() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner2D: no enemy_scene assigned")
		return

	var point: Variant = _pick_candidate(min_player_distance)
	if point == null:
		return

	var enemy: Node2D = enemy_scene.instantiate()
	enemy.global_position = point
	get_parent().add_child(enemy)


func _spawn_stalker() -> void:
	if stalker_scene == null:
		return

	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	var points: Array[Vector2] = PathSpawn.walkable_points(self, player.global_position, stalker_max_distance)
	var usable: Array[Vector2] = []
	for point in points:
		if point.distance_to(player.global_position) >= stalker_min_distance:
			usable.append(point)
	if usable.is_empty():
		usable = points
	if usable.is_empty():
		return

	var spawn_point: Vector2 = usable[_rng.randi() % usable.size()]
	var stalker: Node2D = stalker_scene.instantiate()
	stalker.global_position = spawn_point
	get_parent().add_child(stalker)


func _pick_candidate(min_distance_from_player: float) -> Variant:
	if _candidates.is_empty():
		return null

	var player := get_tree().get_first_node_in_group("player")
	var best: Vector2 = _candidates[0]
	var best_distance := -1.0

	for point in _candidates:
		var distance := INF
		if is_instance_valid(player):
			distance = point.distance_to(player.global_position)
			if distance >= min_distance_from_player:
				return point
		else:
			return point
		if distance > best_distance:
			best_distance = distance
			best = point

	return best
