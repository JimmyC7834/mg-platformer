extends Node

const SPEED: float = 3500
const ACCELERATION: float = 30

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var ray_cast_2d: RayCast2D = $"../Flip/RayCast2D"
@onready var vision_area: VisionArea = $"../Flip/VisionArea"

var parent: Enemy
var state: Callable = state_idle

var dir: int = 1
var is_attacking: bool = false
var timer: float = 0

func _ready() -> void:
    if get_parent() is Enemy:
        parent = get_parent()
        parent.on_attacked.connect(func (): $"../TintFade".tint(Color.INDIAN_RED, 0.25))
        parent.on_death.connect(parent.queue_free)
        
        vision_area.on_player_entered.connect(
            func ():
                if is_attacking: return
                animated_sprite_2d.play("walk")
                timer = 0
                state = state_chase
        )
        
        animated_sprite_2d.play("idle")

func _physics_process(delta: float) -> void:
    parent.apply_gravity(delta)

    print(state)
    state.call(delta)
    
    $"../Flip".scale.x = dir
    animated_sprite_2d.flip_h = dir < 0
    
    parent.move_and_slide()

func state_idle(delta):
    parent.velocity.x = lerp(parent.velocity.x, 0.0, ACCELERATION * delta)

    timer += delta
    if timer < 1.5: return

    if randf() < 0.75:
        dir *= -1
            
    animated_sprite_2d.play("walk")
    state = state_roam
    timer = 0

func state_roam(delta):
    timer += delta
    parent.velocity.x = lerp(parent.velocity.x, dir * SPEED * delta, ACCELERATION * delta)

    if timer < 2.0: return
    
    animated_sprite_2d.play("idle")
    state = state_idle
    timer = 0

func state_chase(delta):
    timer += delta
    dir = -1 if (Global.player.global_position.x - parent.global_position.x) < 0 else 1
    parent.velocity.x = lerp(parent.velocity.x, dir * SPEED * delta, ACCELERATION * delta)
    
    var dist: float = Global.player.global_position.distance_to(parent.global_position)
    if dist < 200:
        state = state_attack
    elif dist > 320 and timer > 15:
        timer = 0
        state = state_idle

func state_attack(delta):
    parent.velocity.x = lerp(parent.velocity.x, 0.0, ACCELERATION * delta)
    if is_attacking: return
    is_attacking = true
    animated_sprite_2d.play("attack")
    $"../HitboxAnimation".play("attack")
    await $"../HitboxAnimation".animation_finished
    is_attacking = false
    
    animated_sprite_2d.play("walk")
    timer = 0
    state = state_chase
