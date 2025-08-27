extends Node

enum ActionType { NONE, ATTACK, HEAL, REVIVE }

var unit_container: UnitsContainer

func init(new_unit_container: UnitsContainer) -> void:
	unit_container = new_unit_container

func get_unit_cells() -> Array[Vector2i]:
	var unit_coords: Array[Vector2i] = []
	for unit in unit_container.units:
		unit_coords.append(unit.get_current_cell())
	return unit_coords
	
func get_units() -> Array[Unit]:
	return unit_container.units
	
func get_units_by_faction(faction: UnitDefinition.Faction) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in unit_container.units:
		if unit.faction == faction: units.append(unit)
	return units
	
func cell_to_unit(cell: Vector2i) -> Unit:
	for unit in unit_container.units:
		if unit.get_current_cell() == cell: return unit
	return null
