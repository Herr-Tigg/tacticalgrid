class_name LevelUI extends Node2D

@onready var timer_label: Label = $TimerLabel

var turn_timer: Timer

func init(new_turn_timer: Timer) -> void:
	turn_timer = new_turn_timer
	

func _process(_delta: float) -> void:
	if not turn_timer.is_stopped():
		var time_left_of_turn: int = floori(turn_timer.time_left)
		timer_label.text = str(time_left_of_turn)
	
