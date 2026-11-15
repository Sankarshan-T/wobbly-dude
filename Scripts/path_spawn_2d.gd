class_name PathSpawn2D
extends RefCounted
## Helpers for finding spawn points that sit on the walkable path.
##
## A level's walkable path is defined by the TileMapLayer that also contains
## collision (wall) tiles: its non-collision cells are the corridor. Background
## layers (no collision tiles) are ignored so enemies don't spawn "everywhere".


## World-space points on the walkable path within [param radius] of [param center].
static func walkable_points(anchor: Node2D, center: Vector2, radius: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var layers := _walkable_layers(anchor)
	if layers.is_empty():
		return points

	var space := anchor.get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = 1

	var radius_sq := radius * radius
	for layer in layers:
		for cell in layer.get_used_cells():
			var data := layer.get_cell_tile_data(cell)
			if data == null or data.get_collision_polygons_count(0) > 0:
				continue

			var world: Vector2 = layer.to_global(layer.map_to_local(cell))
			if world.distance_squared_to(center) > radius_sq:
				continue

			params.position = world
			if not space.intersect_point(params, 1).is_empty():
				continue

			points.append(world)

	return points


static func _walkable_layers(anchor: Node) -> Array[TileMapLayer]:
	var all: Array[TileMapLayer] = []
	for node in anchor.get_tree().root.find_children("*", "TileMapLayer", true, false):
		all.append(node)

	var wall_layers: Array[TileMapLayer] = []
	for layer in all:
		if _has_collision_tiles(layer):
			wall_layers.append(layer)

	return wall_layers if not wall_layers.is_empty() else all


static func _has_collision_tiles(layer: TileMapLayer) -> bool:
	for cell in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		if data != null and data.get_collision_polygons_count(0) > 0:
			return true
	return false
