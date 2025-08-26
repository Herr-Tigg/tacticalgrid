class_name AIController extends UnitController

var cost_path_cell: float = 1.0
var cost_attack: float = -2.0
var cost_kill: float = -3.0

var connected_unit: Unit

var selected_action: Dictionary

func init(_connected_unit: Unit) -> void:
	super(_connected_unit)
	connected_unit = _connected_unit
	

#region State management

func enter_selecting_move() -> void:
	selection = ActionSelection.new()
	calculate_action_costs()
	selection.select_move(selected_action["move_cell"])
	if selected_action["attack_cell"] != null:
		selection.select_attack(selected_action["attack_cell"])
	connected_unit.update_state(connected_unit.State.MOVING)
	

#endregion

func calculate_action_costs() -> void:
	var opposing_faction: UnitDefinition.Faction = UnitDefinition.Faction.FRIENDLY if connected_unit.faction == UnitDefinition.Faction.ENEMY else UnitDefinition.Faction.ENEMY 
	var movements: Array[ActionDefinition] = connected_unit.movements
	var attacks: Array[ActionDefinition] = connected_unit.attack_patterns
	var source_cell: Vector2i = connected_unit.get_current_cell()
	var damage: int = connected_unit.get_damage()
	
	var opposing_units := GlobalData.get_units_by_faction(opposing_faction)
	var traversable_cells: Array[Vector2i] = Navigation.get_selectable_cells(
		movements,
		source_cell,
	)
	
	var calculated_moves: Array[Dictionary] = []
	for move_cell in traversable_cells:
		for unit in opposing_units:
			var shortest_path := Navigation.get_shortest_path(move_cell, unit.get_current_cell(), [source_cell])
			shortest_path.pop_back()
			var move_cost := shortest_path.size() * cost_path_cell
			calculated_moves.append({
				"move_cell": move_cell,
				"path": shortest_path,
				"move_cost": move_cost,
			})
	
	var calculated_actions: Array[Dictionary] = []
	for move in calculated_moves:
		var move_cell: Vector2i = move["move_cell"]
		var move_cost: float = move["move_cost"]
		calculated_actions.append({
			"move_cell": move_cell,
			"attack_cell": null,
			"cost": move_cost,
		})
		
		var attackable_cells := Navigation.get_selectable_cells(
			attacks,
			move_cell,
			[source_cell],
		)
		
		for unit in opposing_units:
			var attack_cell: Vector2i = unit.get_current_cell()
			if attack_cell not in attackable_cells: continue
			
			var is_kill: bool = unit.get_current_health() <= damage
			var attack_cost: float = cost_kill if is_kill else cost_attack
			calculated_actions.append({
				"move_cell": move_cell,
				"attack_cell": attack_cell,
				"cost": move_cost + attack_cost,
			})
			
	var cheapest_action: Dictionary = {"cost": 10000}
	for action in calculated_actions:
		if action["cost"] >= cheapest_action["cost"]: continue
		cheapest_action = action
		
	print(cheapest_action)
	selected_action = cheapest_action
	

func get_selected_action() -> Dictionary:
	return selected_action
