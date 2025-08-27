class_name MovingState extends UnitState

@onready var unit: Unit = owner

var move_selected: bool = false
var selected_move_cell: Vector2i
var action_selected: bool = false
var selected_action_cell: Vector2i

func enter(_previous_state_path: String, data: Dictionary = {}) -> void:
	move_selected = data["move_selected"]
	selected_move_cell = data["selected_move_cell"]
	action_selected = data["action_selected"]
	selected_action_cell = data["selected_action_cell"]
	
	if not move_selected:
		transition_to_next_state()
		return
	
	if selected_move_cell.x < unit.current_cell.x: unit.animated_sprite.flip_h = true
	elif selected_move_cell.x > unit.current_cell.x: unit.animated_sprite.flip_h = false
	

func update(delta: float) -> void:
	'''Move the unit towards the target cell'''
	var target_position := Navigation.cell_to_world(selected_move_cell)
	unit.position = unit.position.move_toward(target_position, delta * unit.movement_speed)
	
	if unit.position.is_equal_approx(target_position):
		unit.current_cell = selected_move_cell
		unit.position = target_position
		transition_to_next_state()
	

func transition_to_next_state() -> void:
	if move_selected and action_selected:
		finished.emit("ActionState", {
			"action_selected": action_selected,
			"selected_action_cell": selected_action_cell,
		})
		return
	
	finished.emit("TurnCompletedState", {})
	
