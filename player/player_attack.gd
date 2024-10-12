extends Node

const SLASH_SFXS = [
    preload("res://assets/audio/slash_sfx/footstep_snow_001.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_002.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_003.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_004.ogg"),
]

const DEFAULT_HIT_KNOCBACK: float = 400
const M_ATK_MANA_COST: float = 10

const BASE_ATK_POWER: float = 2.5
const M_ATK_FACTOR: float = 1.5

@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var hitbox_anim: AnimationPlayer = $"../HitboxAnimation"
@onready var hit_box: Area2D = $"../Rotatable/HitBox"
@onready var release_hit_box: Area2D = $"../Rotatable/ReleaseHitBox"

var player: Player

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
    
    hit_box.body_entered.connect(handle_hitbox_entered)
    release_hit_box.body_entered.connect(handle_release_hitbox_entered)
    player.request_perform_attack.connect(handle_attack_request)
    player.request_release_attack.connect(handle_release_attack_request)

func handle_attack_request():
    var buffer = "ATK" if Input.is_action_just_pressed("ATK") else "M_ATK"
    if hitbox_anim.is_playing():
        if hitbox_anim.current_animation_length - hitbox_anim.current_animation_position > 0.125:
            return
        await hitbox_anim.animation_finished
    
    if not player.is_on_floor():
        player.velocity.y = 0
    
    Audio.play(SLASH_SFXS.pick_random(), 0.0, 2.0)
    
    match buffer:
        "ATK":
            hitbox_anim.play("atk01")
            animated_sprite_2d.play("atk0%d" % randi_range(1, 2))
            slash_animation.play("slash0%d" % randi_range(1, 4))
            player.on_attack.emit()
        "M_ATK":
            hitbox_anim.play("m_atk01")
            animated_sprite_2d.play("m_atk0%d" % randi_range(1, 2))
            slash_animation.play("m_slash0%d" % randi_range(1, 4))
            player.mana += M_ATK_MANA_COST
            player.on_m_attack.emit()

func handle_release_attack_request():
    if not player.is_on_floor():
        player.velocity.y = 0
    hitbox_anim.play("RESET")
    hitbox_anim.play("release")
    player.on_attack.emit()

func handle_hitbox_entered(body: Node2D):
    if body is Enemy:
        Util.hitstop(0.08)
        body.velocity.x = player.facing * DEFAULT_HIT_KNOCBACK * 5
        body.attacked(BASE_ATK_POWER)

    player.velocity.x = player.facing * -DEFAULT_HIT_KNOCBACK
    player.velocity.x *= 1.0 if player.is_on_floor() else 0.25

func handle_release_hitbox_entered(body: Node2D):
    if body is Enemy:
        Util.hitstop(0.15)
        body.velocity.x = player.facing * DEFAULT_HIT_KNOCBACK * 8
        body.attacked(BASE_ATK_POWER * 3)
