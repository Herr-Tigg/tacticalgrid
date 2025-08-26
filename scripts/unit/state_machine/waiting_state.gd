class_name WaitingState extends UnitState

@onready var unit: Unit = owner

func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	unit.turn_started.connect(on_turn_started)
	unit.knocked_out.connect(on_knocked_out)
	

func exit() -> void:
	unit.knocked_out.disconnect(on_knocked_out)
	unit.turn_started.disconnect(on_turn_started)
	

func on_turn_started() -> void:
	finished.emit("SelectionState", {})
	

func on_knocked_out() -> void:
	finished.emit("KnockedOutState", {})
