class_name PlayerController extends UnitController

var connected_unit: Unit


func init(_connected_unit: Unit) -> void:
	super(_connected_unit)
	connected_unit = _connected_unit
	get_parent()
	

#region State management

func enter_selecting_move() -> void:
	selection = ActionSelection.new()
	selection.traversable_cells = Navigation.get_selectable_cells(connected_unit.movements, connected_unit.get_current_cell())
	EventBus.listen_for_move_input.emit(connected_unit)
	

func enter_selecting_attack() -> void:
	var opposing_units := GlobalData.get_units_by_faction(connected_unit.opposing_faction)
	var selectable_cells := Navigation.get_selectable_cells(
		connected_unit.attack_patterns,
		selection.move_cell,
		[connected_unit.get_current_cell()],
	)
	
	var attackable_cells: Array[Vector2i] = []
	for unit in opposing_units:
		var unit_cell: Vector2i = unit.get_current_cell()
		if unit_cell in selectable_cells: attackable_cells.append(unit_cell)
	selection.attackable_cells = attackable_cells
	
	EventBus.move_selected.emit(selection.move_cell)
	

func enter_ready() -> void:
	EventBus.attack_selected.emit(selection.attack_cell)

#endregion
#region Input handling

func handle_input_select() -> void:
	'''Select a cell for which to apply the current action'''
	if connected_unit.current_state not in [Unit.State.SELECTING_MOVE, Unit.State.SELECTING_ATTACK]: return
	
	var target_cell := Navigation.world_to_cell(connected_unit.get_global_mouse_position())
	if connected_unit.current_state == Unit.State.SELECTING_MOVE:
		if not target_cell in selection.traversable_cells: return
		selection.select_move(target_cell)
		connected_unit.update_state(Unit.State.SELECTING_ATTACK)
	elif connected_unit.current_state == Unit.State.SELECTING_ATTACK:
		if not target_cell in selection.attackable_cells: return
		selection.select_attack(target_cell)
		connected_unit.connected_unit.update_state(Unit.State.READY)
	

func handle_input_cancel() -> void:
	'''Cancel and return to the previous action'''
	if connected_unit.current_state == Unit.State.SELECTING_ATTACK:
		selection.deselect_move()
		connected_unit.update_state(Unit.State.SELECTING_MOVE)
	elif connected_unit.current_state == Unit.State.READY:
		selection.deselect_attack()
		connected_unit.update_state(Unit.State.SELECTING_ATTACK)
	

func handle_input_ack_selection() -> void:
	'''Acknowledge selected actions and proceed to perform them'''
	connected_unit.update_state(Unit.State.MOVING)
	

func _unhandled_input(event: InputEvent) -> void:
	if connected_unit.current_state not in [Unit.State.SELECTING_MOVE, Unit.State.SELECTING_ATTACK, Unit.State.READY]: return
	
	if event.is_action_pressed("select"): handle_input_select()
	elif event.is_action_pressed("cancel"): handle_input_cancel()
	elif event.is_action_pressed("ack_selection"): handle_input_ack_selection()
	
#endregion
