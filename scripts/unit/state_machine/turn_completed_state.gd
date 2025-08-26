extends UnitState

@onready var unit: Unit = owner

func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	EventBus.turn_completed.emit(unit)
	finished.emit("WaitingState", {})
	
