extends Node

const LEVEL = preload("res://scenes/level.tscn")

var level: Level

func _ready() -> void:
	EventBus.start_new_round.connect(on_start_new_round)
	start_level()
	

func start_level() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	

func clean_up_level() -> void:
	level.queue_free()
	

func on_start_new_round() -> void:
	clean_up_level()
	start_level()
	
