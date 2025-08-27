class_name AttackingState extends UnitState

const ATTACK_DURATION: float = 1.0

@onready var unit: Unit = owner
@onready var timer: Timer = Timer.new()

var action_type: GlobalData.ActionType
var action_selected: bool = false
var selected_action_cell: Vector2i

func _ready() -> void:
	timer.one_shot = true
	add_child(timer)
	

func enter(_previous_state_path: String, data: Dictionary = {}) -> void:
	action_selected = data["action_selected"]
	selected_action_cell = data["selected_action_cell"]
	
	if not action_selected:
		finished.emit("TurnCompletedState", {})
		return
	
	if selected_action_cell.x < unit.current_cell.x: unit.animated_sprite.flip_h = true
	elif selected_action_cell.x > unit.current_cell.x: unit.animated_sprite.flip_h = false
	
	discover_action_type()
	
	match action_type:
		GlobalData.ActionType.NONE:
			finished.emit("TurnCompletedState", {})
			return
		GlobalData.ActionType.ATTACK:
			timer.start(ATTACK_DURATION)
		GlobalData.ActionType.HEAL:
			timer.start(ATTACK_DURATION)
		GlobalData.ActionType.REVIVE:
			pass
	EventBus.action_started.emit(action_type)

func exit() -> void:
	timer.stop()
	

func update(_delta: float) -> void:
	if not timer.is_stopped(): return
	
	EventBus.action_ended.emit(action_type, unit, selected_action_cell)
	finished.emit("TurnCompletedState", {})
	

func discover_action_type() -> void:
	var target_unit: Unit = GlobalData.cell_to_unit(selected_action_cell)
	if target_unit.faction != unit.faction:
		action_type = GlobalData.ActionType.ATTACK
		return
	if target_unit.current_health < target_unit.max_health and unit.healing_enabled:
		action_type = GlobalData.ActionType.HEAL
	
