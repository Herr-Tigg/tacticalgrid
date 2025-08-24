class_name Unit extends Node2D

signal unit_dead(unit: Unit)

enum State {WAITING, SELECTING_MOVE, SELECTING_ATTACK, READY, MOVING, ATTACKING, DYING}

const HEALTH_SPRITE_DATA: Dictionary[String, float] = {
	"width": 14,
	"high_x": 17,
	"mid_x": 33,
	"low_x": 49,
	"low_percentage": 0.25,
	"mid_percentage": 0.5,
}

class Turn:
	'''Class recording the decisions made during a given turn'''
	var move_selected: bool = false
	var move_cell: Vector2i = Vector2i.ZERO
	var traversable_cells: Array[Vector2i] = []
	
	var attack_selected: bool = false
	var attack_cell: Vector2i = Vector2i.ZERO
	var attackable_cells: Array[Vector2i] = []
	
	func select_move(selected_cell: Vector2i) -> void:
		move_selected = true
		move_cell = selected_cell
	
	func deselect_move() -> void:
		move_selected = false
	
	func select_attack(selected_cell: Vector2i) -> void:
		attack_selected = true
		attack_cell = selected_cell
	
	func deselect_attack() -> void:
		attack_selected = false
	

@export var animated_sprite: AnimatedSprite2D
@export var health_bar_sprite: Sprite2D
@export var movement_speed: float = 30.0

# User definition
var faction: UnitDefinition.Faction
var max_health: int
var speed: int
var damage: int
var movements: Array[ActionDefinition]
var attack_patterns: Array[ActionDefinition]
var sprite_frames: SpriteFrames

var timer: Timer
var current_state: State
var turn: Turn
var opposing_faction: UnitDefinition.Faction
var current_health: int
var current_cell: Vector2i

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

func init(spawn_cell: Vector2i, unit_def: UnitDefinition, turn_timer: Timer) -> void:
	faction = unit_def.faction
	max_health = unit_def.max_health
	speed = unit_def.speed
	damage = unit_def.damage
	movements = unit_def.movements
	attack_patterns = unit_def.attack_patterns
	sprite_frames = unit_def.sprite_frames
	
	turn_timer.timeout.connect(on_turn_timeout)
	
	current_state = State.WAITING
	if faction == UnitDefinition.Faction.FRIENDLY: opposing_faction = UnitDefinition.Faction.ENEMY
	else: opposing_faction = UnitDefinition.Faction.FRIENDLY
	current_health = max_health
	current_cell = spawn_cell
	position = Navigation.cell_to_world(current_cell)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.flip_h = current_cell.x > 0 as bool
	animated_sprite.play("idle")
	

#region Internal state management

func update_state(new_state: State) -> void:
	'''Update the unit's internal state and perform appropriate actions'''
	current_state = new_state
	
	match new_state:
		State.WAITING:
			EventBus.turn_completed.emit(self)
		State.SELECTING_MOVE:
			turn = Turn.new()
			turn.traversable_cells = Navigation.get_selectable_cells(movements, current_cell)
			
			EventBus.listen_for_move_input.emit(self)
		State.SELECTING_ATTACK:
			var opposing_units := GlobalData.get_units_by_faction(opposing_faction)
			var selectable_cells := Navigation.get_selectable_cells(
				attack_patterns,
				turn.move_cell,
				[current_cell],
			)
			
			var attackable_cells: Array[Vector2i] = []
			for unit in opposing_units:
				var unit_cell: Vector2i = unit.get_current_cell()
				if unit_cell in selectable_cells: attackable_cells.append(unit_cell)
			turn.attackable_cells = attackable_cells
			
			EventBus.move_selected.emit(turn.move_cell)
		State.READY:
			EventBus.attack_selected.emit(turn.attack_cell)
		State.MOVING:
			EventBus.selection_acknowledged.emit()
			if turn.move_selected:
				if turn.move_cell.x < current_cell.x: animated_sprite.flip_h = true
				elif turn.move_cell.x > current_cell.x: animated_sprite.flip_h = false
			else: update_state(State.WAITING)
		State.ATTACKING:
			if turn.attack_selected:
				if turn.attack_cell.x < current_cell.x: animated_sprite.flip_h = true
				elif turn.attack_cell.x > current_cell.x: animated_sprite.flip_h = false
				
				timer.start(1.0)
				EventBus.attack_started.emit()
			else: update_state(State.WAITING)
		State.DYING:
			unit_dead.emit(self)
	

#endregion
#region Input handling

func handle_input_select() -> void:
	'''Select a cell for which to apply the current action'''
	if current_state not in [State.SELECTING_MOVE, State.SELECTING_ATTACK]: return
	
	var target_cell := Navigation.world_to_cell(get_global_mouse_position())
	if current_state == State.SELECTING_MOVE:
		if not target_cell in turn.traversable_cells: return
		turn.select_move(target_cell)
		update_state(State.SELECTING_ATTACK)
	elif current_state == State.SELECTING_ATTACK:
		if not target_cell in turn.attackable_cells: return
		turn.select_attack(target_cell)
		update_state(State.READY)
	

func handle_input_cancel() -> void:
	'''Cancel and return to the previous action'''
	if current_state == State.SELECTING_ATTACK:
		turn.deselect_move()
		update_state(State.SELECTING_MOVE)
	elif current_state == State.READY:
		turn.deselect_attack()
		update_state(State.SELECTING_ATTACK)
	

func handle_input_ack_selection() -> void:
	'''Acknowledge selected actions and proceed to perform them'''
	update_state(State.MOVING)
	

func _input(event: InputEvent) -> void:
	if current_state not in [State.SELECTING_MOVE, State.SELECTING_ATTACK, State.READY]: return
	
	if event.is_action_pressed("select"): handle_input_select()
	elif event.is_action_pressed("cancel"): handle_input_cancel()
	elif event.is_action_pressed("ack_selection"): handle_input_ack_selection()
	
#endregion
#region Frame dependant logic

func move(delta: float) -> void:
	'''Move the unit towards the target cell'''
	var target_position := Navigation.cell_to_world(turn.move_cell)
	position = position.move_toward(target_position, delta*movement_speed)
	
	if position.is_equal_approx(target_position):
		current_cell = turn.move_cell
		position = target_position
		update_state(State.ATTACKING)
	

func attack(_delta: float) -> void:
	'''No per-frame attack logic for now -> Simply finish the turn.'''
	if not timer.is_stopped(): return
	
	EventBus.attack_ended.emit(self, turn.attack_cell)
	update_state(State.WAITING)
	

func _process(delta: float) -> void:
	'''Runs on every frame'''
	match current_state:
		State.MOVING: move(delta)
		State.ATTACKING: attack(delta)
	

#endregion
#region Signal handling

func on_turn_timeout() -> void:
	'''Perform the selected move and attack if any, when timer runs out'''
	if current_state not in [State.SELECTING_MOVE, State.SELECTING_ATTACK, State.READY]: return
	update_state(State.MOVING)
	

#endregion
#region Public functions

func start_turn() -> void:
	'''Start the unit's turn by transitioning out of the waiting state'''
	update_state(State.SELECTING_MOVE)
	

func take_damage(inflicted_damage: int) -> void:
	'''Register damage inflicted by an opponent'''
	current_health = clampi(current_health - inflicted_damage, 0, 255)
	
	health_bar_sprite.region_rect.size.x = clamp(
		HEALTH_SPRITE_DATA["width"] * current_health / float(max_health),
		0.0,
		HEALTH_SPRITE_DATA["width"],
	)
	
	if current_health <= max_health * HEALTH_SPRITE_DATA["low_percentage"]:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["low_x"]
	elif current_health <= max_health * HEALTH_SPRITE_DATA["mid_percentage"]:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["mid_x"]
	else:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["high_x"]
	
	if current_health <= 0.0: update_state(State.DYING)
	

func get_speed() -> int:
	'''Get the unit's current speed, which affects its place in the turn order'''
	return speed
	

func get_current_cell() -> Vector2i:
	'''Get the cell on which the unit is currently positioned'''
	return current_cell
	

func get_traversable_cells() -> Array[Vector2i]:
	'''Get cells to which the unit can move this turn'''
	return turn.traversable_cells
	

func get_attackable_cells() -> Array[Vector2i]:
	'''Get cells that contain opponents that ma be attacked'''
	return turn.attackable_cells
	

func get_sprite_data() -> Dictionary[String, Variant]:
	'''Get the flip_h and a texture to place at the selected move cell'''
	return {
		"flip_h": animated_sprite.flip_h,
		"move_sprite": sprite_frames.get_frame_texture("idle", 0),
	}

#endregion
