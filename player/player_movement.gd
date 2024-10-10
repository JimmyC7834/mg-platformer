extends Node

const JUMP_HEIGHT = 780
const MIN_JUMP_HEIGHT = 15000
const MAX_COYOTE_TIME = 6
const JUMP_BUFFER_TIME = 10
const WALL_JUMP_AMOUNT = 18000
const WALL_JUMP_TIME = 10
const WALL_SLIDE_FACTOR = 0.8
const WALL_HORIZONTAL_TIME = 30
const GRAVITY = 1900
const LIMIT_SPEED_Y = 1000
const DASH_SPEED = 360

var coyoteTimer = 0
var jumpBufferTimer = 0
var wallJumpTimer = 0
var wallHorizontalTimer = 0
var dashTime = 0

var canJump = false
var friction = false
var wall_sliding = false
var trail = false
var isDashing = false
var hasDashed = false
var isGrabbing = false

@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
var player: Player
var in_anim: bool = false

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
        player.request_jump.connect(jump)

func _physics_process(delta):
    #player.move_and_slide()
    return
    
    #dash(delta)
    
    #wallSlide(delta)

    #basic vertical movement mechanics
    #if wallJumpTimer > WALL_JUMP_TIME:
        #wallJumpTimer = WALL_JUMP_AMOUNT
        #if !isDashing && !isGrabbing:
            #horizontalMovement(delta)
    #else:
        #wallJumpTimer += 1
    
    if !canJump:
        if !wall_sliding:
            if player.velocity.y >= 0:
                animated_sprite_2d.play("fall")
            elif player.velocity.y < 0:
                animated_sprite_2d.play("jump")

    #jumping mechanics and coyote time
    if player.is_on_floor():
        canJump = true
        coyoteTimer = 0
    else:
        coyoteTimer += 1
        if coyoteTimer > MAX_COYOTE_TIME:
            canJump = false
            coyoteTimer = 0
        friction = true
    
    jumpBuffer(delta)

    if Input.is_action_just_pressed("JUMP"):
        if canJump:
            jump()
            frictionOnAir()
        else:
            if $"../Rotatable"/RayCast2D.is_colliding():
                wallJump(delta)
            frictionOnAir()
            jumpBufferTimer = JUMP_BUFFER_TIME #amount of frame

    setJumpHeight(delta)
    jumpBuffer(delta)

func coyote_time(delta):
    if player.is_on_floor():
        canJump = true
        coyoteTimer = 0
    else:
        coyoteTimer += 1
        if coyoteTimer > MAX_COYOTE_TIME:
            canJump = false
            coyoteTimer = 0
        friction = true
    
    jumpBuffer(delta)

func apply_gravity(delta):
    if player.is_on_floor():
        return

    if player.velocity.y <= LIMIT_SPEED_Y:
        if !isDashing:
            player.velocity.y += GRAVITY * delta
    else:
        player.velocity.y = LIMIT_SPEED_Y

func jump():
    player.velocity.y = -JUMP_HEIGHT

func wallJump(delta):
    wallJumpTimer = 0
    player.velocity.x = -WALL_JUMP_AMOUNT * $"../Rotatable".scale.x * delta
    player.velocity.y = -JUMP_HEIGHT * delta
    $"../Rotatable".scale.x = -$"../Rotatable".scale.x

func wallSlide(delta):
    if !canJump:
        if $"../Rotatable/RayCast2D".is_colliding():
            wall_sliding = true
            isGrabbing = false
            player.velocity.y = player.velocity.y * WALL_SLIDE_FACTOR
        else:
            wall_sliding = false
            isGrabbing = false

func frictionOnAir():
    if friction:
        player.velocity.x = lerp(player.velocity.x, 0.0, 0.01)

func jumpBuffer(delta):
    if jumpBufferTimer > 0:
        if player.is_on_floor():
            jump()
        jumpBufferTimer -= 1

func setJumpHeight(delta):
    if Input.is_action_just_released("ui_up"):
        if player.velocity.y < -MIN_JUMP_HEIGHT * delta:
            player.velocity.y = -MIN_JUMP_HEIGHT * delta

func apply_velocity_decay(delta):
    player.velocity.x = lerp(player.velocity.x, 0.0, 0.2)

func dash():
    player.velocity.x = player.facing * DASH_SPEED
    
    #if !hasDashed:
        #if Input.is_action_just_pressed("DASH"):
            #player.velocity = player.axis * DASH_SPEED * delta
            ##Input.start_joy_vibration(0, 1, 1, 0.2)
            #isDashing = true
            #hasDashed = true
            ##$Camera/ShakeCamera2D.add_trauma(0.5)
#
    #if isDashing:
        #trail = true
        #dashTime += 1
        #if dashTime >= int(0.25 * 1 / delta):
            #isDashing = false
            #trail = false
            #dashTime = 0
#
    #if player.is_on_floor() && player.velocity.y >= 0:
        #hasDashed = false
