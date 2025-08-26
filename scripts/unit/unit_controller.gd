class_name UnitController extends Node

class ActionSelection:
	'''Class recording the decisions made during a given turn'''
	var move_selected: bool = false
	var move_cell: Vector2i = Vector2i.ZERO
	var traversable_cells: Array[Vector2i] = []
	
	var attack_selected: bool = false
	var attack_cell: Vector2i = Vector2i.ZERO
	var attackable_cells: Array[Vector2i] = []
	
	func select_move(selected_cell: Vector2i) -> void:
		move_selected = true
		move_cell = selected_cell
	
	func deselect_move() -> void:
		move_selected = false
	
	func select_attack(selected_cell: Vector2i) -> void:
		attack_selected = true
		attack_cell = selected_cell
	
	func deselect_attack() -> void:
		attack_selected = false

var selection: ActionSelection

func init(_connected_unit: Unit) -> void:
	pass
	

func enter_waiting() -> void:
	pass
	

func enter_selecting_move() -> void:
	pass
	

func enter_selecting_attack() -> void:
	pass
	

func enter_ready() -> void:
	pass
	

func enter_moving() -> void:
	pass
	

func enter_attacking() -> void:
	pass
	

func enter_dying() -> void:
	pass
	
