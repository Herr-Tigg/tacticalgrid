class_name ActionDefinition extends Resource

enum Type { MOVEMENT, ATTACK }
enum Mode { TRUNCATE_BEFORE, TRUNCATE_AT }

@export var type: Type
@export var mode: Mode
@export var path: Array[Vector2i]
