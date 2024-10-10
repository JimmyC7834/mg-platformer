extends Camera2D

@export var target: Node2D

func _ready():
    global_position = target.global_position
    Global.player_camera = self
    
func _process(delta: float) -> void:
    global_position = Vector2(
        lerpi(global_position.x, target.global_position.x, 0.2),
        lerpi(global_position.y, target.global_position.y, 0.2),
    )

static func lerpi(origin: float, target: float, weight: float) -> float:
    target = floorf(target)
    origin = floorf(origin)
    var distance: float = ceilf(absf(target - origin) * weight)
    return move_toward(origin, target, distance)
