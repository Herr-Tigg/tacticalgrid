class_name UnitDefinition extends Resource

enum Faction {FRIENDLY, ENEMY}

@export var faction: Faction
@export var max_health: int
@export var speed: int
@export var damage: int
@export var movements: Array[ActionDefinition]
@export var attack_patterns: Array[ActionDefinition]
@export var sprite_frames: SpriteFrames
