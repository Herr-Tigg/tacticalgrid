class_name SelectionState extends UnitState

@onready var unit: Unit = owner

var cost_path_cell: float = 1.0
var cost_attack: float = -2.0
var cost_kill: float = -3.0

var traversable_cells: Array[Vector2i]
var move_selected: bool
var selected_move_cell: Vector2i
var attackable_cells: Array[Vector2i]
var attack_selected: bool
var selected_attack_cell: Vector2i

func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	traversable_cells = []
	attackable_cells = []
	move_selected = false
	attack_selected = false
	
	unit.turn_timer.timeout.connect(on_turn_timeout)
	
	if unit.is_playable:
		traversable_cells = Navigation.get_selectable_cells(unit.movements, unit.current_cell)
		EventBus.listen_for_move_input.emit(unit, traversable_cells)
	else:
		calculate_action_costs()
		transition_to_next_state()
	

func exit() -> void:
	unit.turn_timer.timeout.disconnect(on_turn_timeout)
	

func handle_input(event: InputEvent) -> void:
	if not unit.is_playable: return
		
	if event.is_action_pressed("select"): handle_input_select()
	elif event.is_action_pressed("cancel"): handle_input_cancel()
	elif event.is_action_pressed("ack_selection"): handle_input_ack_selection()
	

func on_turn_timeout() -> void:
	'''Perform the selected move and attack if any, when timer runs out'''
	transition_to_next_state()
	

func transition_to_next_state() -> void:
	EventBus.selection_acknowledged.emit()
	var next_state_path: String = "MovingState" if move_selected else "TurnCompletedState"
	
	finished.emit(next_state_path, {
		"move_selected": move_selected,
		"selected_move_cell": selected_move_cell,
		"attack_selected": attack_selected,
		"selected_attack_cell": selected_attack_cell,
	})
	

#region Player logic

func handle_input_select() -> void:
	'''Select a cell for which to apply the current action'''
	if move_selected and attack_selected: return
	
	var target_cell := Navigation.world_to_cell(owner.get_global_mouse_position())
	if not move_selected:
		if not target_cell in traversable_cells: return
		move_selected = true
		selected_move_cell = target_cell
		
		var opposing_units := GlobalData.get_units_by_faction(unit.opposing_faction)
		var selectable_cells := Navigation.get_selectable_cells(
			unit.attack_patterns,
			selected_move_cell,
			[unit.current_cell],
		)
		
		attackable_cells = []
		for opposing_unit in opposing_units:
			var cell: Vector2i = opposing_unit.current_cell
			if cell in selectable_cells: attackable_cells.append(cell)
		
		EventBus.move_selected.emit(selected_move_cell, attackable_cells)
	elif not attack_selected:
		if not target_cell in attackable_cells: return
		attack_selected = true
		selected_attack_cell = target_cell
		EventBus.attack_selected.emit(selected_attack_cell)
	

func handle_input_cancel() -> void:
	'''Cancel and return to the previous action'''
	if attack_selected:
		attack_selected = false
		EventBus.move_selected.emit(selected_move_cell, attackable_cells)
	elif move_selected:
		move_selected = false
		EventBus.listen_for_move_input.emit(unit, traversable_cells)
	

func handle_input_ack_selection() -> void:
	'''Acknowledge selected actions and proceed to perform them'''
	transition_to_next_state()
	

#endregion
#region AI logic

func calculate_action_costs() -> void:
	var opposing_faction := unit.opposing_faction
	var movements := unit.movements
	var attacks := unit.attack_patterns
	var source_cell := unit.current_cell
	var damage := unit.damage
	
	var opposing_units := GlobalData.get_units_by_faction(opposing_faction)
	traversable_cells = Navigation.get_selectable_cells(
		movements,
		source_cell,
	)
	
	var calculated_moves: Array[Dictionary] = []
	for move_cell in traversable_cells:
		for opposing_unit in opposing_units:
			var shortest_path := Navigation.get_shortest_path(
				move_cell,
				opposing_unit.get_current_cell(),
				[source_cell]
			)
			shortest_path.pop_back()
			var move_cost := shortest_path.size() * cost_path_cell
			calculated_moves.append({
				"move_cell": move_cell,
				"path": shortest_path,
				"move_cost": move_cost,
			})
	
	var calculated_actions: Array[Dictionary] = []
	for move in calculated_moves:
		var move_cell: Vector2i = move["move_cell"]
		var move_cost: float = move["move_cost"]
		calculated_actions.append({
			"move_cell": move_cell,
			"attack_cell": null,
			"cost": move_cost,
		})
		
		attackable_cells = Navigation.get_selectable_cells(
			attacks,
			move_cell,
			[source_cell],
		)
		
		for opposing_unit in opposing_units:
			var attack_cell: Vector2i = opposing_unit.get_current_cell()
			if attack_cell not in attackable_cells: continue
			
			var is_kill: bool = opposing_unit.get_current_health() <= damage
			var attack_cost: float = cost_kill if is_kill else cost_attack
			calculated_actions.append({
				"move_cell": move_cell,
				"attack_cell": attack_cell,
				"cost": move_cost + attack_cost,
			})
			
	var cheapest_action: Dictionary = {"cost": 10000}
	for action in calculated_actions:
		if action["cost"] >= cheapest_action["cost"]: continue
		cheapest_action = action
		
	if "move_cell" in cheapest_action:
		move_selected = true
		selected_move_cell = cheapest_action["move_cell"]
	if "attack_cell" in cheapest_action and cheapest_action["attack_cell"] != null:
		attack_selected = true
		selected_attack_cell = cheapest_action["attack_cell"]
	

#endregion
