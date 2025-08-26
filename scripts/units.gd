class_name UnitsContainer extends Node2D

enum State {SCHEDULING, ACTING, ROUND_OVER, AWAITING_RESTART}

const UNIT: PackedScene = preload("res://scenes/unit.tscn")

class TurnQueue:
	'''
	A priority queue determining the turn order based on action value.
	Higher speed gives a lower action value, allowing a unit to act earlier.
	'''
	const INITIAL_ACTION_VALUE: int = 10000
	
	var queue: Array[Dictionary] # [{"unit": Unit, "action_value": int}, ...]
	
	func get_base_action_value(unit: Unit) -> int:
		return ceil(INITIAL_ACTION_VALUE / float(unit.get_speed()))
	
	func insert(new_unit: Unit) -> void:
		'''Insert a unit at the appropriat place in the priority queue'''
		var old_queue := queue
		queue = []
		
		var new_turn: Dictionary[String, Variant] = {
			"unit": new_unit,
			"action_value": get_base_action_value(new_unit),
		}
		
		while not old_queue.is_empty():
			var turn: Dictionary[String, Variant] = old_queue.front()
			if new_turn["action_value"] < turn["action_value"]: break
			turn["action_value"] -= 0
			queue.append(turn)
			old_queue.pop_front()
		
		queue.append(new_turn)
		
		while not old_queue.is_empty():
			var turn: Dictionary[String, Variant] = old_queue.pop_front()
			queue.append(turn)
		
	
	func dequeue() -> Unit:
		'''Pop off the first unit in the queue and update all action values'''
		var next_turn: Dictionary[String, Variant] = queue.pop_front()
		for turn in queue:
			turn["action_value"] -= next_turn["action_value"]
		return next_turn["unit"]
		
	
	func remove(unit: Unit) -> void:
		'''Remove a unit from the queue, update action values if necessary'''
		if queue.front()["unit"] == unit: dequeue()
		
		var old_queue := queue
		queue = []
		
		while not old_queue.is_empty():
			var turn: Dictionary[String, Variant] = old_queue.pop_front()
			if turn["unit"] != unit: queue.append(turn)
		
	

# Keep just below 8 to avoid UI flickering on timer start
@export var turn_time_seconds: float = 7.99

var current_state: State
var turn_timer: Timer
var units: Array[Unit]
var turn_queue: TurnQueue
var winner: UnitDefinition.Faction

func _ready() -> void:
	connect_round_signals()
	current_state = State.SCHEDULING
	turn_queue = TurnQueue.new()
	

func init(level_def: LevelDefinition, turn_timer_instance: Timer) -> void:
	'''Level dependent initialisation'''
	turn_timer = turn_timer_instance
	turn_timer.one_shot = true
	
	for idx in level_def.friendly_units.size():
		var is_playable := idx in level_def.playables
		spawn_unit(level_def.friendly_units[idx], level_def.friendly_spawn_cells[idx], is_playable)
	for idx in level_def.opponent_units.size():
		spawn_unit(level_def.opponent_units[idx], level_def.opponent_spawn_cells[idx], false)
	

#region Signal handling

func on_selection_acknowledged() -> void:
	'''The unit has made all necessary decisions, stop the turn timer'''
	turn_timer.stop()
	

func on_attack_ended(attacker: Unit, target_cell: Vector2i) -> void:
	'''A unit has attacked another at a particular cell'''
	for unit in units:
		if unit.get_current_cell() == target_cell:
			unit.take_damage(attacker.damage)
			return
	

func on_turn_completed(unit: Unit) -> void:
	'''A unit has completed their turn, schedule next turn'''
	turn_queue.insert(unit)
	current_state = State.SCHEDULING
	

func on_unit_defeated(unit: Unit) -> void:
	units.erase(unit)
	turn_queue.remove(unit)
	unit.queue_free()
	
	check_round_state()
	

#endregion
#region Input handling

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.AWAITING_RESTART: return
	
	if event.is_action_pressed("ui_accept"):
		EventBus.start_new_round.emit()
	

#endregion
#region Frame dependant logic

func _process(_delta: float) -> void:
	match current_state:
		State.SCHEDULING:
			# We call next_turn in _process to allow all end of turn signals
			# to finish before starting a new turn
			next_turn()
		State.ROUND_OVER:
			EventBus.round_over.emit(winner)
			current_state = State.AWAITING_RESTART
	

#endregion
#region Public functions

func start_round() -> void:
	'''Populate the turn queue and have the first unit start its turn'''
	for unit in units:
		turn_queue.insert(unit)
	next_turn()
	

#endregion
#region Helper functions

func connect_round_signals() -> void:
	EventBus.selection_acknowledged.connect(on_selection_acknowledged)
	EventBus.attack_ended.connect(on_attack_ended)
	EventBus.turn_completed.connect(on_turn_completed)
	EventBus.unit_defeated.connect(on_unit_defeated)
	

func disconnect_round_signals() -> void:
	EventBus.selection_acknowledged.disconnect(on_selection_acknowledged)
	EventBus.attack_ended.disconnect(on_attack_ended)
	EventBus.turn_completed.disconnect(on_turn_completed)
	EventBus.unit_defeated.disconnect(on_unit_defeated)
	

func spawn_unit(unit_def: UnitDefinition, cell: Vector2i, is_playable: bool) -> void:
	'''Instantiate a particular unit at a particular cell'''
	for unit in units:
		assert(cell != unit.get_current_cell(), "Cannot spawn units on same cell: " + str(cell))
	
	var new_unit = UNIT.instantiate()
	new_unit.init(cell, unit_def, is_playable, turn_timer)
	units.append(new_unit)
	add_child(new_unit)
	

func next_turn() -> void:
	'''Make the next unit in the queue act'''
	var next_unit := turn_queue.dequeue()
	current_state = State.ACTING
	turn_timer.start(turn_time_seconds)
	next_unit.start_turn()
	

func check_round_state() -> void:
	var friendly: UnitDefinition.Faction = UnitDefinition.Faction.FRIENDLY
	var enemy: UnitDefinition.Faction = UnitDefinition.Faction.ENEMY
	var units_per_faction: Dictionary[UnitDefinition.Faction, int] = {
		friendly: 0,
		enemy: 0,
	}
	
	for unit in units:
		units_per_faction[unit.faction] += 1
	
	if 0 not in units_per_faction.values(): return
	
	if units_per_faction[friendly] == 0: winner = enemy
	# TODO: Add enemy wave logic
	else: winner = friendly
	
	disconnect_round_signals()
	current_state = State.ROUND_OVER
	

#endregion
