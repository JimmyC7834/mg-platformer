extends Node

const GRAVITY: float = 1900
const LIMIT_SPEED_Y: float = 1000
const ACCELERATION: float = 2500
const MAX_SPEED: float = 12000
const JUMP_HEIGHT: float = 780

@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var hitbox_animation: AnimationPlayer = $"../HitboxAnimation"

var player: Player
var fsm: FSM = FSM.new()

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
        player.on_damaged.connect(
            func ():
                if player.is_parrying:
                    fsm.set_state(_state_parriying)
                elif not player.invincible:
                    fsm.set_state(_state_damaged))
        
        player.request_release_attack.connect(
            func ():
                fsm.set_state(_state_release))

        player.on_mana_break.connect(mana_break_tint)

        fsm.set_state(_state_idle)

func _physics_process(delta):
    getInputAxis()
    fsm.physics_update(delta)
    request_release()
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
            
            if Input.is_action_just_pressed("ATK"):
                player.request_perform_attack.emit()
                await animated_sprite_2d.animation_finished
                animated_sprite_2d.play("idle")
            elif Input.is_action_just_pressed("M_ATK"):
                fsm.set_state(_state_m_atk)
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
            elif Input.is_action_just_pressed("ATK"):
                player.request_perform_attack.emit()
            elif Input.is_action_just_pressed("M_ATK"):
                fsm.set_state(_state_m_atk)
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

var _state_m_atk = {
    "start":
        func ():
            player.request_m_attack.emit(),
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
            apply_velocity_decay(_delta)
            
            if Input.is_action_just_released("M_ATK"):
                player.request_stop_m_attack.emit()
                fsm.set_state(_state_idle)
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
            fsm.set_state(_state_idle)
            for i in range(3):
                await Util.wait(0.25)
                $"../TintFade".tint(Color.DIM_GRAY, 0.25)
            player.invincible = false,
            
    "physics_update":
        func (_delta):
            apply_gravity(_delta)
}

var _state_parriying = {
    "start":
        func ():
            print("parry")
            player.invincible = true
            player.velocity.y = 0
            player.velocity.x = -player.facing * Player.HURT_KNOCKBACK * 5
            Util.hitstop(0.15)
            
            animated_sprite_2d.play("release")
            animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
            await Util.wait((6.0 + 1) / 16)
            animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
            fsm.set_state(_state_idle)
            player.invincible = false,
            
    "physics_update":
        func (_delta):
            apply_velocity_decay(_delta)
}

var _state_release = {
    "start":
        func ():
            if player.invincible or player.is_parrying: return
            player.velocity.x = 0
            player.is_parrying = true
            Util.hitstop(0.1)
            animated_sprite_2d.play("release")
            player.velocity.x = -player.facing * 75
            player.velocity.y = 0
            $"../TintFade".tint(Color.DARK_ORCHID, 6.0 / 16)
            await Util.wait((6.0 + 1) / 16)
            fsm.set_state(_state_idle)
            player.is_parrying = false,

    "physics_update":
        func (_delta):
            pass
}

func mana_break_tint():
    if player.is_mana_break:
        $"../TintFade".tint(Color.BLUE_VIOLET, 0.35)
        await Util.wait(0.35)
        mana_break_tint()

func request_release():
    if Input.is_action_just_pressed("RELEASE") and not hitbox_animation.is_playing():
        player.request_perform_release.emit()

func apply_gravity(delta):
    if player.is_on_floor():
        return

    if player.velocity.y <= LIMIT_SPEED_Y:
        player.velocity.y += GRAVITY * delta
    else:
        player.velocity.y = LIMIT_SPEED_Y

func horizontalMovement(delta):
    if abs(player.axis.x) == 1:
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
