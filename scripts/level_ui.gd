class_name LevelUI extends CanvasLayer

enum State {ROUND_ONGOING, ROUND_OVER}

@onready var timer_label: Label = $TimerLabel
@onready var round_over_label: Label = $RoundOverLabel
@onready var round_over_instruction_label: Label = $RoundOverInstructionLabel

var current_state: State
var turn_timer: Timer

func _ready() -> void:
	EventBus.round_over.connect(on_round_over)
	current_state = State.ROUND_ONGOING

func init(new_turn_timer: Timer) -> void:
	turn_timer = new_turn_timer
	

func _process(_delta: float) -> void:
	if current_state != State.ROUND_ONGOING: return
	
	if not turn_timer.is_stopped():
		var time_left_of_turn: int = floori(turn_timer.time_left)
		timer_label.text = str(time_left_of_turn)
	

func on_round_over(winner: UnitDefinition.Faction) -> void:
	round_over_label.text = "Victory" if winner == UnitDefinition.Faction.FRIENDLY else "Defeat"
	round_over_label.visible = true
	round_over_instruction_label.visible = true
	timer_label.visible = false
	current_state = State.ROUND_OVER
	
