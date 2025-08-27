extends Node

@warning_ignore_start("unused_signal")
signal listen_for_move_input(unit: Unit, traversable_cells: Array[Vector2i])
signal move_selected(cell: Vector2i, attackable_cells: Array[Vector2i])
signal attack_selected(cell: Vector2i)
signal selection_acknowledged
signal action_started(type: GlobalData.ActionType)
signal action_ended(type: GlobalData.ActionType, actor: Unit, target_cell: Vector2i)
signal turn_completed(unit: Unit)
signal unit_defeated(unit: Unit)
signal round_over(winner: UnitDefinition.Faction)
signal start_new_round
