class_name Unit extends Node2D

signal turn_started
signal knocked_out

const HEALTH_SPRITE_DATA: Dictionary[String, float] = {
	"width": 14,
	"high_x": 17,
	"mid_x": 33,
	"low_x": 49,
	"low_percentage": 0.25,
	"mid_percentage": 0.5,
}

@onready var state_machine: UnitStateMachine = $UnitStateMachine

@export var animated_sprite: AnimatedSprite2D
@export var health_bar_sprite: Sprite2D
@export var movement_speed: float = 30.0

# User definition
var faction: UnitDefinition.Faction
var sprite_frames: SpriteFrames
var max_health: int
var speed: int
var movements: Array[ActionDefinition]
var damage: int
var attack_patterns: Array[ActionDefinition]
var healing_strength: int
var healing_enabled: bool

var is_playable: bool
var turn_timer: Timer
var timer: Timer
var opposing_faction: UnitDefinition.Faction
var current_health: int
var current_cell: Vector2i

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

func init(
	spawn_cell: Vector2i,
	unit_def: UnitDefinition,
	is_playable_unit: bool,
	_turn_timer: Timer,
) -> void:
	faction = unit_def.faction
	sprite_frames = unit_def.sprite_frames
	max_health = unit_def.max_health
	speed = unit_def.speed
	movements = unit_def.movements
	damage = unit_def.damage
	attack_patterns = unit_def.attack_patterns
	healing_strength = unit_def.healing_strength
	healing_enabled= unit_def.healing_enabled
	
	turn_timer = _turn_timer
	is_playable = is_playable_unit
	
	if faction == UnitDefinition.Faction.FRIENDLY: opposing_faction = UnitDefinition.Faction.ENEMY
	else: opposing_faction = UnitDefinition.Faction.FRIENDLY
	current_health = max_health
	current_cell = spawn_cell
	position = Navigation.cell_to_world(current_cell)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.flip_h = current_cell.x > 0 as bool
	animated_sprite.play("idle")
	

func update_health_bar() -> void:
	health_bar_sprite.region_rect.size.x = clamp(
		HEALTH_SPRITE_DATA["width"] * current_health / float(max_health),
		0.0,
		HEALTH_SPRITE_DATA["width"],
	)
	
	if current_health <= max_health * HEALTH_SPRITE_DATA["low_percentage"]:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["low_x"]
	elif current_health <= max_health * HEALTH_SPRITE_DATA["mid_percentage"]:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["mid_x"]
	else:
		health_bar_sprite.region_rect.position.x = HEALTH_SPRITE_DATA["high_x"]
	

#region Public functions

func start_turn() -> void:
	'''Start the unit's turn by transitioning out of the waiting state'''
	turn_started.emit()
	

func take_damage(inflicted_damage: int) -> void:
	'''Register damage inflicted by an opponent'''
	current_health = clampi(current_health - inflicted_damage, 0, 255)
	update_health_bar()
	if current_health <= 0.0: knocked_out.emit()
	

func receive_heal(applied_healing_strength: int) -> void:
	current_health = clampi(current_health + applied_healing_strength, 0, max_health)
	update_health_bar()
	

func get_is_playable() -> bool:
	'''Get whether the unit is player controlled or an NPC'''
	return is_playable

func get_speed() -> int:
	'''Get the unit's current speed, which affects its place in the turn order'''
	return speed
	

func get_damage() -> int:
	return damage
	

func get_current_health() -> int:
	return current_health
	

func get_current_cell() -> Vector2i:
	'''Get the cell on which the unit is currently positioned'''
	return current_cell
	

func get_sprite_data() -> Dictionary[String, Variant]:
	'''Get the flip_h and a texture to place at the selected move cell'''
	return {
		"flip_h": animated_sprite.flip_h,
		"move_sprite": sprite_frames.get_frame_texture("idle", 0),
	}

#endregion
