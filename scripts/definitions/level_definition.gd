class_name LevelDefinition extends Resource

@export_category("Map")
@export var map_to_load: PackedScene

@export_category("Friendly units")
@export var friendly_units: Array[UnitDefinition]
@export var friendly_spawn_cells: Array[Vector2i]

@export_category("Opponent units")
@export var opponent_units: Array[UnitDefinition]
@export var opponent_spawn_cells: Array[Vector2i]
