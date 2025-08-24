class_name MapEffects extends Node2D

enum State {WAITING, SELECT_MOVE, SELECT_ATTACK, AWAIT_ACK}

const SOURCE_ID := 0
const ATLAS_COORDS_NULL := Vector2i(0, 0)
const ATLAS_COORDS_HOVER := Vector2i(1, 0)
const ATLAS_COORDS_SELECTABLE := Vector2i(3, 0)
const ATLAS_COORDS_BLOCKED := Vector2i(4, 0)
const ATLAS_COORDS_ATTACK := Vector2i(5, 0)

class CameraShake:
	var shake_speed: float = 200.0
	var shake_strength: float = 3.0
	var shake_decay_rate: float = 3.0
	
	var camera: Camera2D
	
	var active: bool = false
	var noise: FastNoiseLite
	var noise_i: float = 0.0
	var current_shake_strength: float = 0.0
	
	func _init(new_camera: Camera2D) -> void:
		camera = new_camera
		noise = FastNoiseLite.new()
		noise.seed = randi()
		
	func start() -> void:
		current_shake_strength = shake_strength
		active = true
		
	func shake_if_active(delta: float) -> void:
		if not active: return
		
		current_shake_strength = lerp(current_shake_strength, 0.0, shake_decay_rate * delta)
		noise_i += shake_speed * delta
		
		camera.offset = Vector2(
			noise.get_noise_2d(1, noise_i) * current_shake_strength,
			noise.get_noise_2d(100, noise_i) * current_shake_strength,
		)
		
	func end() -> void:
		camera.offset = Vector2.ZERO
		active = false
		
	

var highlight_layer: TileMapLayer
var move_indicator_sprite: Sprite2D
var camera_shake: CameraShake
var current_state: State
var current_cell: Vector2i = Vector2i(INF, INF)
var current_unit: Unit
var selected_move_cell: Vector2i
var selected_attack_cell: Vector2i

func _ready() -> void:
	EventBus.listen_for_move_input.connect(on_listen_for_move)
	EventBus.move_selected.connect(on_move_selected)
	EventBus.attack_selected.connect(on_attack_selected)
	EventBus.selection_acknowledged.connect(on_selection_acknowledged)
	EventBus.attack_started.connect(on_attack_started)
	EventBus.attack_ended.connect(on_attack_ended)
	EventBus.turn_completed.connect(on_turn_completed)
	
	move_indicator_sprite = Sprite2D.new()
	move_indicator_sprite.z_index = 10
	move_indicator_sprite.self_modulate.a = 0.6
	add_child(move_indicator_sprite)
	

func init(
	tile_map: TileMapLayer,
	highlight_layer_instance: TileMapLayer,
	camera: Camera2D,
) -> void:
	highlight_layer = highlight_layer_instance
	for cell in tile_map.get_used_cells():
		highlight_layer.set_cell(cell, SOURCE_ID, ATLAS_COORDS_NULL)
	
	camera_shake = CameraShake.new(camera)
	current_state = State.WAITING
	

#region Internal state handling

func update_state(new_state: State) -> void:
	current_state = new_state
	
	clear_highlights()
	
	match new_state:
		State.WAITING: pass
		State.SELECT_MOVE:
			for cell in current_unit.get_traversable_cells():
				highlight_layer.set_cell(cell, SOURCE_ID, ATLAS_COORDS_SELECTABLE)
			handle_hover(current_cell)
		State.SELECT_ATTACK:
			for cell in current_unit.get_attackable_cells():
				highlight_layer.set_cell(cell, SOURCE_ID, ATLAS_COORDS_SELECTABLE)
			handle_hover(current_cell)
			set_move_sprite()
		State.AWAIT_ACK:
			highlight_layer.set_cell(selected_attack_cell, SOURCE_ID, ATLAS_COORDS_ATTACK)
			set_move_sprite()
	

#endregion
#region Signal handling

func on_listen_for_move(unit: Unit) -> void:
	current_unit = unit
	update_state(State.SELECT_MOVE)
	

func on_move_selected(cell: Vector2i) -> void:
	selected_move_cell = cell
	update_state(State.SELECT_ATTACK)
	

func on_attack_selected(cell: Vector2i) -> void:
	selected_attack_cell = cell
	update_state(State.AWAIT_ACK)
	

func on_selection_acknowledged() -> void:
	update_state(State.WAITING)
	

func on_attack_started() -> void:
	camera_shake.start()
	

func on_attack_ended(_attacker: Unit, _target_cell: Vector2i) -> void:
	camera_shake.end()
	

func on_turn_completed(_unit: Unit) -> void:
	update_state(State.WAITING)
	

#endregion
#region Frame dependant logic

func handle_hover(new_cell: Vector2i) -> void:
	'''Apply appropriate highlight effects to cells based on mouse hover'''
	var highlight: Vector2i
	
	if current_state == State.SELECT_MOVE:
		var traverable_cells := current_unit.get_traversable_cells()
		
		if cell_exists(current_cell):
			highlight = ATLAS_COORDS_SELECTABLE if current_cell in traverable_cells else ATLAS_COORDS_NULL
			highlight_layer.set_cell(current_cell, SOURCE_ID, highlight)
		if cell_exists(new_cell):
			highlight = ATLAS_COORDS_HOVER if new_cell in traverable_cells else ATLAS_COORDS_BLOCKED
			highlight_layer.set_cell(new_cell, SOURCE_ID, highlight)
	elif current_state == State.SELECT_ATTACK:
		var attackable_cells := current_unit.get_attackable_cells()
		
		if cell_exists(current_cell) and current_cell != selected_move_cell:
			highlight = ATLAS_COORDS_SELECTABLE if current_cell in attackable_cells else ATLAS_COORDS_NULL
			highlight_layer.set_cell(current_cell, SOURCE_ID, highlight)
		if cell_exists(new_cell) and new_cell != selected_move_cell:
			highlight = ATLAS_COORDS_HOVER if new_cell in attackable_cells else ATLAS_COORDS_BLOCKED
			highlight_layer.set_cell(new_cell, SOURCE_ID, highlight)
		
	current_cell = new_cell
	

func _process(delta: float) -> void:
	var new_cell := Navigation.world_to_cell(get_global_mouse_position())
	
	if current_state in [State.SELECT_MOVE, State.SELECT_ATTACK] and new_cell != current_cell:
		handle_hover(new_cell)
	
	camera_shake.shake_if_active(delta)
	

#endregion
#region Helper functions

func clear_highlights() -> void:
	'''Remove highlights from all cells in the tile map'''
	for cell in highlight_layer.get_used_cells():
		highlight_layer.set_cell(cell, SOURCE_ID, ATLAS_COORDS_NULL)
	move_indicator_sprite.texture = null

func cell_exists(cell: Vector2i) -> bool:
	'''Check whether the cell is part of the tile map'''
	return highlight_layer.get_cell_source_id(cell) != -1

func set_move_sprite() -> void:
	'''Render a transparent unit sprite at the selected move cell'''
	move_indicator_sprite.position = Navigation.cell_to_world(selected_move_cell)
	
	var sprite_data := current_unit.get_sprite_data()
	move_indicator_sprite.texture = sprite_data["move_sprite"]
	
	if selected_move_cell.x < current_unit.get_current_cell().x:
		move_indicator_sprite.flip_h = true
	elif selected_move_cell.x > current_unit.get_current_cell().x:
		move_indicator_sprite.flip_h = false
	else:
		move_indicator_sprite.flip_h = sprite_data["flip_h"]

#endregion
