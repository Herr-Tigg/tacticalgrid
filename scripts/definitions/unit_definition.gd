class_name UnitDefinition extends Resource

enum Faction {FRIENDLY, ENEMY}

@export var faction: Faction
@export var sprite_frames: SpriteFrames
@export var max_health: int
@export var speed: int

@export_category("Movement")
@export var movements: Array[ActionDefinition]

@export_category("Actions")
@export var damage: int
@export var attack_patterns: Array[ActionDefinition]

@export var healing_strength: int
@export var healing_enabled: bool
