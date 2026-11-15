class_name EnemySpawner2D
extends Node2D
## Drops enemies onto the walkable path around itself, in waves.
##
## Drop one of these into a level and assign [member enemy_scene]. Each entry in
## [member wave_sizes] is one wave; the next wave starts once the current one has
## been cleared (after [member wave_delay]). Spawn points are picked at random
## from the walkable path and never reused, so enemies do not stack on a single
## spot.
##
## If the player is being pursued ([member GameState.stalker_active]) and a
## [member stalker_scene] is set, one relentless chaser is spawned on the path
## near the player so the pursuer "follows" them into the 2D world.

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 460.0
@export var min_player_distance: float = 140.0
## How many enemies each wave contains. Two entries = two waves.
@export var wave_sizes: PackedInt32Array = PackedInt32Array([4, 6])
## Pause between the last enemy of a wave dying and the next wave arriving.
@export var wave_delay: float = 3.0
## Fallback used if [member wave_sizes] is empty.
@export var spawn_count: int = 4

@export_group("Stalker")
@export var stalker_scene: PackedScene
@export var spawn_stalker_if_active: bool = true
@export var stalker_min_distance: float = 200.0
@export var stalker_max_distance: float = 380.0

const PathSpawn := preload("res://Scripts/path_spawn_2d.gd")

var _rng := RandomNumberGenerator.new()
var _candidates: Array[Vector2] = []
var _used: Array[Vector2] = []
var _wave_alive: Array[Node] = []
var _wave_index: int = 0


func _ready() -> void:
	_rng.randomize()

	# let the tilemap colliders register before we query the physics space
	await get_tree().physics_frame
	await get_tree().physics_frame

	_candidates = PathSpawn.walkable_points(self, global_position, spawn_radius)

	_start_wave()

	if GameState.stalker_active and spawn_stalker_if_active:
		_spawn_stalker()


func _start_wave() -> void:
	var count := _wave_size(_wave_index)
	_wave_alive.clear()

	for i in count:
		var enemy := _spawn_one()
		if enemy == null:
			continue
		_wave_alive.append(enemy)
		if enemy.has_signal("died"):
			enemy.died.connect(_on_wave_enemy_died)

	_wave_index += 1


func _wave_size(index: int) -> int:
	if wave_sizes.is_empty():
		return maxi(spawn_count, 0)
	if index < wave_sizes.size():
		return maxi(wave_sizes[index], 0)
	return maxi(wave_sizes[wave_sizes.size() - 1], 0)


func _on_wave_enemy_died(enemy: Node) -> void:
	_wave_alive.erase(enemy)
	if _wave_alive.is_empty() and _wave_index < wave_sizes.size():
		_begin_next_wave()


func _begin_next_wave() -> void:
	await get_tree().create_timer(wave_delay).timeout
	if not is_inside_tree() or not _wave_alive.is_empty():
		return
	if _wave_index >= wave_sizes.size():
		return
	_start_wave()


func _spawn_one() -> Node2D:
	if enemy_scene == null:
		push_warning("EnemySpawner2D: no enemy_scene assigned")
		return null

	var point: Variant = _pick_candidate(min_player_distance)
	if point == null:
		return null

	var enemy: Node2D = enemy_scene.instantiate()
	enemy.global_position = point
	get_parent().add_child(enemy)
	return enemy


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


## Pick a random unused spawn point. Prefers points far enough from the player,
## then any unused point, then any point at all.
func _pick_candidate(min_distance_from_player: float) -> Variant:
	if _candidates.is_empty():
		return null

	var player := get_tree().get_first_node_in_group("player")

	var unused_far: Array[Vector2] = []
	var unused: Array[Vector2] = []
	for point in _candidates:
		if _used.has(point):
			continue
		unused.append(point)
		if not is_instance_valid(player) or point.distance_to(player.global_position) >= min_distance_from_player:
			unused_far.append(point)

	var pool: Array[Vector2] = unused_far
	if pool.is_empty():
		pool = unused
	if pool.is_empty():
		pool = _candidates

	var chosen: Vector2 = pool[_rng.randi() % pool.size()]
	if not _used.has(chosen):
		_used.append(chosen)
	return chosen
