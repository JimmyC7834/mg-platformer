extends Node

const SPEED: float = 3000
const ACCELERATION: float = 30

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var ray_cast_2d: RayCast2D = $"../RayCast2D"

var dir: Vector2 = Vector2.RIGHT

var parent: Enemy

func _ready() -> void:
    if get_parent() is Enemy:
        parent = get_parent()
        parent.on_attacked.connect(func (): $"../TintFade".tint(Color.INDIAN_RED, 0.25))
        parent.on_death.connect(parent.queue_free)
        
        animated_sprite_2d.play("jump")

func _physics_process(delta: float) -> void:
    parent.apply_gravity(delta)

    if ray_cast_2d.is_colliding():
        dir.x *= -1
    
    ray_cast_2d.scale.x = dir.x
    animated_sprite_2d.flip_h = dir.x == -1

    if dir.x > 0:
        parent.velocity.x = lerp(parent.velocity.x, SPEED * delta, ACCELERATION * delta)
    elif dir.x < 0:
        parent.velocity.x = lerp(parent.velocity.x, -SPEED * delta, ACCELERATION * delta)

    parent.move_and_slide()
