extends Node

const GRAVITY: float = 1900
const LIMIT_SPEED_Y: float = 1000
const ACCELERATION: float = 2500
const MAX_SPEED: float = 12000
const JUMP_HEIGHT: float = 780

@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
var player: Player

var fsm: FSM = FSM.new()

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
        player.on_damaged.connect(
            func():
                if not player.invincible:
                    fsm.set_state(_state_damaged))
        fsm.set_state(_state_idle)

func _physics_process(delta):
    getInputAxis()
    fsm.physics_update(delta)
    player.move_and_slide()

var _state_idle = {
    "start":
        func ():
            if abs(player.velocity.y) < 100.0:
                chain_animation(["land", "idle"])     
            elif abs(player.velocity.x) > 100.0:
                chain_animation(["brake", "idle"])
            else:   
                animated_sprite_2d.play("idle"),
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
            apply_velocity_decay(_delta)
            
            if Input.is_action_just_pressed("ATK") or Input.is_action_just_pressed("M_ATK"):
                player.request_perform_attack.emit()
                await animated_sprite_2d.animation_finished
                animated_sprite_2d.play("idle")
            
            if player.axis.x != 0:
                fsm.set_state(_state_run)
            elif not player.is_on_floor():
                fsm.set_state(_state_fall)
            elif Input.is_action_just_pressed("JUMP"):
                fsm.set_state(_state_jump)
            elif Input.is_action_just_pressed("DASH"):
                fsm.set_state(_state_dash)
}

var _state_run = {
    "start":
        func ():
            animated_sprite_2d.play("run"),
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
            horizontalMovement(_delta)
            
            if Input.is_action_just_pressed("JUMP"):
                fsm.set_state(_state_jump)

            elif not player.is_on_floor():
                fsm.set_state(_state_fall)
            elif Input.is_action_just_pressed("ATK") or Input.is_action_just_pressed("M_ATK"):
                player.request_perform_attack.emit()
            elif Input.is_action_just_pressed("DASH"):
                fsm.set_state(_state_dash)
            elif player.axis.x == 0:
                fsm.set_state(_state_idle)
}

var _state_jump = {
    "start":
        func ():
            player.velocity.y = -JUMP_HEIGHT
            animated_sprite_2d.play("jump"),
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
            horizontalMovement(_delta)
    
            if Input.is_action_just_pressed("M_ATK"):
                player.request_perform_attack.emit()
            
            if player.velocity.y >= 0:
                fsm.set_state(_state_fall)
            elif Input.is_action_just_pressed("DASH"):
                fsm.set_state(_state_dash)
            elif Input.is_action_just_released("JUMP"):
                fsm.set_state(_state_fall)

}

var _state_fall = {
    "start":
        func ():
            animated_sprite_2d.play("fall"),
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
            horizontalMovement(_delta)
            
            if Input.is_action_just_pressed("M_ATK"):
                player.request_perform_attack.emit()    
            
            if player.velocity.y < 0:
                player.velocity.y = lerp(player.velocity.y, 0.0, 0.25)

            if player.is_on_floor():
                chain_animation(["land", "idle"])
                fsm.set_state(_state_idle)
            elif Input.is_action_just_pressed("DASH"):
                fsm.set_state(_state_dash)
}

var _state_dash = {
    "start":
        func ():
            animated_sprite_2d.play("dash")
            player.velocity.y = 0
            player.velocity.x = player.facing * Player.DASH_SPEED
            await Util.wait(Player.DASH_SPAN)

            if player.is_on_floor():
                if player.axis.x != 0:
                    fsm.set_state(_state_run)
                else:
                    chain_animation(["brake", "idle"])
                    player.velocity.x = player.facing * 50
                    fsm.set_state(_state_idle)
            else:
                player.velocity.x = player.facing * 200
                fsm.set_state(_state_fall),
}

var _state_damaged = {
    "start":
        func ():
            if player.invincible: return
            player.invincible = true
            player.velocity.x = -player.facing * Player.HURT_KNOCKBACK
            Util.hitstop(0.15)
            
            animated_sprite_2d.play("hurt")
            $"../TintFade".tint(Color.INDIAN_RED, 0.15)
            await Util.wait(0.15)
            player.invincible = false
            fsm.set_state(_state_idle),
            
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
}

func apply_gravity(delta):
    if player.is_on_floor():
        return

    if player.velocity.y <= LIMIT_SPEED_Y:
        player.velocity.y += GRAVITY * delta
    else:
        player.velocity.y = LIMIT_SPEED_Y

func horizontalMovement(delta):
    if player.axis.x != 0:
        player.facing = player.axis.x
        animated_sprite_2d.flip_h = player.facing == 1
        $"../Rotatable".scale.x = player.facing
    
    if $"../Rotatable"/RayCast2D.is_colliding():
        await Util.wait(0.1)
    
    if Input.is_action_pressed("ui_right"):
        player.velocity.x = min(player.velocity.x + ACCELERATION * delta, MAX_SPEED * delta)
    elif Input.is_action_pressed("ui_left"):
        player.velocity.x = max(player.velocity.x - ACCELERATION * delta, -MAX_SPEED * delta)

func apply_velocity_decay(delta):
    player.velocity.x = lerp(player.velocity.x, 0.0, 12 * delta)

func chain_animation(queue: Array[String]):
    for anim in queue:
        animated_sprite_2d.play(anim)
        await animated_sprite_2d.animation_finished

func getInputAxis():
    player.axis = Vector2.ZERO
    player.axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
    player.axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
    player.axis = player.axis.normalized()
