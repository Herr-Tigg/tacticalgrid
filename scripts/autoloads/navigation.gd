extends Node

var tile_map: TileMapLayer
var astar: AStar2D

func init(new_tile_map: TileMapLayer) -> void:
	tile_map = new_tile_map
	astar = AStar2D.new()
	
	var used_cells := tile_map.get_used_cells()
	for i in used_cells.size():
		astar.add_point(i, used_cells[i])
	for i in astar.get_point_count():
		var point_position := astar.get_point_position(i)
		
		var neighbour_cells := [Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(0, -1)]
		for cell in neighbour_cells:
			var cell_id := astar.get_closest_point(point_position + cell, true)
			if not astar.are_points_connected(i, cell_id) and cell_id != i:
				astar.connect_points(i, cell_id)
	

func world_to_cell(mouse_position: Vector2) -> Vector2i:
	var local_position := tile_map.to_local(mouse_position)
	return tile_map.local_to_map(local_position)
	

func cell_to_world(tile_coords: Vector2i) -> Vector2:
	var local_position = tile_map.map_to_local(tile_coords)
	return tile_map.to_global(local_position)
	

func get_selectable_cells(
	actions: Array[ActionDefinition],
	source_cell: Vector2i,
	excluded_blocked_cells: Array[Vector2i] = [],
) -> Array[Vector2i]:
	var selectable_cells: Array[Vector2i] = []
	
	var blocked_cells: Array[Vector2i] = []
	for blocked_cell in GlobalData.get_unit_cells():
		if blocked_cell in excluded_blocked_cells: continue
		blocked_cells.append(blocked_cell)
	
	for action in actions:
		var absolute_path: Array[Vector2i] = []
		var relative_path := action.path
		for relative_cell in relative_path:
			var absolute_cell := source_cell + relative_cell
			if tile_map.get_cell_source_id(absolute_cell) == -1: continue
			absolute_path.append(absolute_cell)
		
		if action.mode == ActionDefinition.Mode.TRUNCATE_BEFORE:
			for cell in absolute_path:
				if cell in blocked_cells: break
				selectable_cells.append(cell)
		if action.mode == ActionDefinition.Mode.TRUNCATE_AT:
			for cell in absolute_path:
				selectable_cells.append(cell)
				if cell in blocked_cells: break
	
	return selectable_cells
	

#region AI logic

func get_shortest_path(
	from: Vector2i,
	to: Vector2i,
	excluded_blocked_cells: Array[Vector2i] = [],
) -> Array[Vector2i]:
	'''Use Astar to get the shortest path between two cells'''
	var shortest_path: Array[Vector2i] = []
	var unit_cells: Array[Vector2i] = GlobalData.get_unit_cells()
	
	var from_id: int = astar.get_closest_point(from, true)
	var to_id: int = astar.get_closest_point(to, true)
	
	var blocked_ids: Array[int] = []
	for cell in unit_cells:
		if cell in excluded_blocked_cells or cell == to: continue
		var blocked_id: int = astar.get_closest_point(cell, true)
		blocked_ids.append(blocked_id)
		astar.set_point_disabled(blocked_id, true)
	
	var shortest_id_path := astar.get_id_path(from_id, to_id, true)
	for id in shortest_id_path:
		shortest_path.append(Vector2i(astar.get_point_position(id)))
	
	for id in blocked_ids:
		astar.set_point_disabled(id, false)
	
	return shortest_path

#endregion
