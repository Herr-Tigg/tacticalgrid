class_name KnockedOutState extends UnitState

@onready var unit: Unit = owner

func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	EventBus.unit_defeated.emit(unit)
	
