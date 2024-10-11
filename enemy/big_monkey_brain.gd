extends Node

const SPEED: float = 3500
const ACCELERATION: float = 30

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var ray_cast_2d: RayCast2D = $"../Flip/RayCast2D"
@onready var vision_area: VisionArea = $"../Flip/VisionArea"

var parent: Enemy
var fsm: FSM = FSM.new()

var dir: int = 1
var is_attacking: bool = false
var timer: float = 0

func _ready() -> void:
    if get_parent() is Enemy:
        parent = get_parent()
        parent.on_attacked.connect(func (): $"../TintFade".tint(Color.INDIAN_RED, 0.25))
        parent.on_death.connect(parent.queue_free)
        
        fsm.set_state(_state_idle)
        vision_area.on_player_entered.connect(
            func ():
                if is_attacking: return
                fsm.set_state(_state_chase))
        
func _physics_process(delta: float) -> void:
    parent.apply_gravity(delta)

    fsm.physics_update(delta)
    
    $"../Flip".scale.x = dir
    animated_sprite_2d.flip_h = dir < 0
    
    parent.move_and_slide()

var _state_idle = {
    "start":
        func ():
            timer = 0
            animated_sprite_2d.play("idle"),
    "physics_update":
        func(_delta):
            parent.velocity.x = lerp(parent.velocity.x, 0.0, ACCELERATION * _delta)

            timer += _delta
            if timer < 1.5: return
            if randf() < 0.8:
                dir *= -1

            fsm.set_state(_state_roam)
}

var _state_roam = {
    "start":
        func ():
            timer = 0
            animated_sprite_2d.play("walk"),
    "physics_update":
        func(_delta):
            timer += _delta
            parent.velocity.x = lerp(parent.velocity.x, dir * SPEED * _delta, ACCELERATION * _delta)

            if timer < 2.0: return
            
            fsm.set_state(_state_idle)
}

var _state_chase = {
    "start":
        func ():
            timer = 0
            animated_sprite_2d.play("walk"),
    "physics_update":
        func(_delta):
            timer += _delta
            dir = -1 if (Global.player.global_position.x - parent.global_position.x) < 0 else 1
            parent.velocity.x = lerp(parent.velocity.x, dir * SPEED * _delta, ACCELERATION * _delta)
            
            var dist: float = Global.player.global_position.distance_to(parent.global_position)
            if dist < 200:
                fsm.set_state(_state_attack)
            elif dist > 320 and timer > 15:
                fsm.set_state(_state_idle)
}

var _state_attack = {
    "start":
        func ():
            is_attacking = true
            animated_sprite_2d.play("attack")
            $"../HitboxAnimation".play("attack")
            await $"../HitboxAnimation".animation_finished
            is_attacking = false
            
            fsm.set_state(_state_chase),
    "physics_update":
        func(_delta):
            parent.velocity.x = lerp(parent.velocity.x, 0.0, ACCELERATION * _delta)
}
