extends Node

const SPEED: float = 3000
const ACCELERATION: float = 30

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var ray_cast_2d: RayCast2D = $"../RayCast2D"

var dir: int = 1

var parent: Enemy
var fsm: FSM = FSM.new()

func _ready() -> void:
    if get_parent() is Enemy:
        parent = get_parent()
        parent.on_attacked.connect(func (): $"../TintFade".tint(Color.INDIAN_RED, 0.25))
        parent.on_death.connect(parent.queue_free)
        
        fsm.set_state(_state_roam)

func _physics_process(delta: float) -> void:
    fsm.physics_update(delta)
    parent.move_and_slide()

var _state_roam = {
    "start":
        func ():
            animated_sprite_2d.play("jump"),
    "physics_update":
        func(_delta):
            parent.apply_gravity(_delta)

            if ray_cast_2d.is_colliding():
                dir *= -1
            
            ray_cast_2d.scale.x = dir
            animated_sprite_2d.flip_h = dir == -1

            parent.velocity.x = lerp(parent.velocity.x, dir * SPEED * _delta, ACCELERATION * _delta)
}
