extends Node

@warning_ignore_start("unused_signal")
signal listen_for_move_input(unit: Unit)
signal move_selected(cell: Vector2i)
signal attack_selected(cell: Vector2i)
signal selection_acknowledged
signal attack_ended(attacker: Unit, target_cell: Vector2i)
signal turn_completed(unit: Unit)
