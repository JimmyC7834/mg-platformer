extends Sprite2D

class_name CardInst

@export var speed: float = 2
@export var vSpeed: float = 1
@export var tOffset: float = 0.0

var origin_position: Vector2
var origin_scale: Vector2
var timer: float = 0

func _ready() -> void:
    origin_position = position
    origin_scale = scale

func _process(delta: float) -> void:
    position = origin_position
    position += Vector2.UP * 20 * sin(vSpeed * (tOffset + timer))
    position += Vector2.RIGHT * 48 * sin(tOffset + PI / 2 + timer)
    scale.x = max(abs(origin_scale.x * sin(tOffset + timer)), 0.05)
    
    z_index = 1 if sin(tOffset + timer) < 0 else -1
    
    timer += speed * delta
    if timer > 2 * PI:
        timer -= 2 * PI
