class_name UnitStateMachine extends Node

@export var initial_state: UnitState

var state: UnitState

func _ready() -> void:
	state = initial_state
	
	for state_node: UnitState in find_children("*", "UnitState"):
		state_node.finished.connect(_transition_to_next_state)
	
	await owner.ready
	state.enter("")
	

func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		printerr(owner.name + ": Unable to transition to non-existing state " + target_state_path)
		return
	
	var previous_state_path: String = state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)
	

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)
	

func _process(delta: float) -> void:
	state.update(delta)
	

func _physics_process(delta: float) -> void:
	state.physics_update(delta)
	
