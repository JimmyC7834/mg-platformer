extends Node

const GRAVITY = 1900
const LIMIT_SPEED_Y = 1000

const ACCELERATION = 2500
const MAX_SPEED = 12000

@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
var player: Player
var state: Callable = state_fall
var in_anim: bool = false

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
        player.on_damaged.connect(
            func():
                if not player.invincible:
                    state = state_damaged)

func _physics_process(delta):
    getInputAxis()
    state.call(delta)
    player.move_and_slide()

func state_idle(delta):
    apply_gravity(delta)
    apply_velocity_decay(delta)
    if player.axis.x != 0:
        animated_sprite_2d.play("run")
        state = state_run
    elif Input.is_action_just_pressed("ATK") or Input.is_action_just_pressed("M_ATK"):
        player.request_perform_attack.emit()
        await animated_sprite_2d.animation_finished
        animated_sprite_2d.play("idle")
    elif Input.is_action_just_pressed("JUMP"):
        animated_sprite_2d.play("jump")
        player.request_jump.emit()
        state = state_jump
    elif Input.is_action_just_pressed("DASH"):
        animated_sprite_2d.play("dash")
        state = state_dash

func state_atk(delta):
    apply_gravity(delta)
    apply_velocity_decay(delta)
    
    if in_anim: return

    if player.axis.x == 0:
        animated_sprite_2d.play("idle")
        state = state_idle
    else:
        animated_sprite_2d.play("run")
        state = state_run

func state_run(delta):
    apply_gravity(delta)
    horizontalMovement(delta)
    
    if Input.is_action_just_pressed("JUMP"):
        animated_sprite_2d.play("jump")
        player.request_jump.emit()
        state = state_jump
    elif Input.is_action_just_pressed("ATK") or Input.is_action_just_pressed("M_ATK"):
        player.request_perform_attack.emit()
        animation_lock()
    elif Input.is_action_just_pressed("DASH"):
        animated_sprite_2d.play("dash")
        state = state_dash
    elif player.axis.x == 0:
        chain_animation(["brake", "idle"])
        state = state_idle

func state_jump(delta):
    apply_gravity(delta)
    horizontalMovement(delta)
    if Input.is_action_just_pressed("M_ATK"):
        player.request_perform_attack.emit()
    
    if player.velocity.y >= 0:
        animated_sprite_2d.play("fall")
        state = state_fall
    elif Input.is_action_just_pressed("DASH"):
        animated_sprite_2d.play("dash")
        state = state_dash
    elif Input.is_action_just_released("JUMP"):
        animated_sprite_2d.play("fall")
        state = state_fall

func state_fall(delta):
    apply_gravity(delta)
    horizontalMovement(delta)
    if Input.is_action_just_pressed("M_ATK"):
        player.request_perform_attack.emit()    
    
    if player.velocity.y < 0:
        player.velocity.y = lerp(player.velocity.y, 0.0, 0.25)

    if player.is_on_floor():
        chain_animation(["land", "idle"])
        state = state_idle
    elif Input.is_action_just_pressed("DASH"):
        animated_sprite_2d.play("dash")
        state = state_dash

func state_dash(delta):
    player.velocity.y = 0
    player.velocity.x = player.facing * Player.DASH_SPEED * delta
    
    if player.is_dashing: return
    await get_tree().create_timer(Player.DASH_SPAN).timeout
    
    if player.is_on_floor():
        if player.axis.x != 0:
            chain_animation(["run"])
            state = state_run
        else:
            chain_animation(["brake", "idle"])
            player.velocity.x = player.facing * 50
            state = state_idle
    else:
        chain_animation(["fall"])
        player.velocity.x = player.facing * 200
        state = state_fall

func state_damaged(delta):
    apply_gravity(delta)
    if player.invincible: return
    player.invincible = true
    player.velocity.x = -player.facing * Player.HURT_KNOCKBACK * delta
    Util.hitstop(0.15)
    
    animated_sprite_2d.play("hurt")
    $"../TintFade".tint(Color.INDIAN_RED, 0.15)
    await get_tree().create_timer(0.15).timeout
    player.invincible = false
    
    recover_state()


func apply_gravity(delta):
    if player.is_on_floor():
        return

    if player.velocity.y <= LIMIT_SPEED_Y:
        player.velocity.y += GRAVITY * delta
    else:
        player.velocity.y = LIMIT_SPEED_Y

func recover_state():
    if player.is_on_floor():
        animated_sprite_2d.play("idle")
        state = state_idle
    else:
        animated_sprite_2d.play("fall")
        state = state_fall

func horizontalMovement(delta):
    if Input.is_action_pressed("ui_right"):
        if $"../Rotatable"/RayCast2D.is_colliding():
            await get_tree().create_timer(0.1).timeout
            player.velocity.x = min(player.velocity.x + ACCELERATION * delta, MAX_SPEED * delta)
            $"../Rotatable".scale.x = 1
        else:
            player.velocity.x = min(player.velocity.x + ACCELERATION * delta, MAX_SPEED * delta)
            $"../Rotatable".scale.x = 1
    elif Input.is_action_pressed("ui_left"):
        if $"../Rotatable"/RayCast2D.is_colliding():
            await get_tree().create_timer(0.1).timeout
            player.velocity.x = max(player.velocity.x - ACCELERATION * delta, -MAX_SPEED * delta)
            $"../Rotatable".scale.x = -1
        else:
            player.velocity.x = max(player.velocity.x - ACCELERATION * delta, -MAX_SPEED * delta)
            $"../Rotatable".scale.x = -1

    if player.axis.x != 0:
        player.facing = player.axis.x
        animated_sprite_2d.flip_h = player.facing == 1

func apply_velocity_decay(delta):
    player.velocity.x = lerp(player.velocity.x, 0.0, 0.2)

func chain_animation(queue: Array[String]):
    for anim in queue:
        animated_sprite_2d.play(anim)
        await animated_sprite_2d.animation_finished

func animation_lock():
    in_anim = true
    await animated_sprite_2d.animation_finished
    in_anim = false

func getInputAxis():
    player.axis = Vector2.ZERO
    player.axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
    player.axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
    player.axis = player.axis.normalized()
