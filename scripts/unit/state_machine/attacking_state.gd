class_name AttackingState extends UnitState

const ATTACK_DURATION: float = 1.0

@onready var unit: Unit = owner
@onready var timer: Timer = Timer.new()

var attack_selected: bool = false
var selected_attack_cell: Vector2i

func _ready() -> void:
	timer.one_shot = true
	add_child(timer)
	

func enter(_previous_state_path: String, data: Dictionary = {}) -> void:
	attack_selected = data["attack_selected"]
	selected_attack_cell = data["selected_attack_cell"]
	
	if not attack_selected:
		finished.emit("TurnCompletedState", {})
		return
	
	if selected_attack_cell.x < unit.current_cell.x: unit.animated_sprite.flip_h = true
	elif selected_attack_cell.x > unit.current_cell.x: unit.animated_sprite.flip_h = false
	
	timer.start(ATTACK_DURATION)
	EventBus.attack_started.emit()
	

func exit() -> void:
	timer.stop()
	

func update(_delta: float) -> void:
	if not timer.is_stopped(): return
	
	EventBus.attack_ended.emit(unit, selected_attack_cell)
	finished.emit("TurnCompletedState", {})
	
