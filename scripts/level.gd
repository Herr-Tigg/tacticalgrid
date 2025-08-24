extends Node

@onready var camera: Camera2D = $Camera2D
@onready var highlight_layer: TileMapLayer = $HighlightLayer
@onready var turn_timer: Timer = $TurnTimer

@export var level_def: LevelDefinition
@export var level_ui: LevelUI
@export var map_effects: MapEffects
@export var unit_container: UnitsContainer

func _ready() -> void:
	var tile_map := level_def.map_to_load.instantiate()
	add_child(tile_map)
	
	Navigation.init(tile_map)
	level_ui.init(turn_timer)
	map_effects.init(tile_map, highlight_layer)
	unit_container.init(level_def, turn_timer)
	GlobalData.init(unit_container)
	unit_container.start_round()
