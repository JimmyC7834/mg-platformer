extends Node

const SLASH_SFXS = [
    preload("res://assets/audio/slash_sfx/footstep_snow_001.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_002.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_003.ogg"),
    preload("res://assets/audio/slash_sfx/footstep_snow_004.ogg"),
]

const DEFAULT_HIT_KNOCBACK: float = 400
const M_ATK_MANA_COST: float = 5
const M_ATK_INTERVAL: float = 0.5

const BASE_ATK_POWER: float = 2.5
const M_ATK_FACTOR: float = 0.5

@onready var projectile_spawn_point: Marker2D = $"../Rotatable/ProjectileSpawnPoint"
@onready var slash_animation: AnimatedSprite2D = $"../Rotatable/SlashAnimation"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var hitbox_anim: AnimationPlayer = $"../HitboxAnimation"
@onready var hit_box: Area2D = $"../Rotatable/HitBox"
@onready var release_hit_box: Area2D = $"../Rotatable/ReleaseHitBox"

var player: Player

var in_m_atk: bool = false
var m_atk_timer: float = M_ATK_INTERVAL
var can_air_m_atk: bool = true

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
    
    hit_box.body_entered.connect(handle_hitbox_entered)
    release_hit_box.body_entered.connect(handle_release_hitbox_entered)
    player.request_perform_attack.connect(handle_attack_request)
    player.request_m_attack.connect(start_m_atk)
    player.request_stop_m_attack.connect(end_m_atk)
    #player.request_release_attack.connect(handle_release_attack_request)

func _process(delta: float) -> void:
    if m_atk_timer <= 0 and in_m_atk:
        animated_sprite_2d.play("m_atk0%d" % randi_range(1, 2))
        Projectiles.spawn_projectile(
            Projectiles.TYPE.DEFAULT,
            projectile_spawn_point.global_position,
            player.facing * Vector2.RIGHT * 400)
        player.set_mana(player.mana + M_ATK_MANA_COST)
        Audio.play(SLASH_SFXS.pick_random(), 0.0, 2.0)
        m_atk_timer = M_ATK_INTERVAL

    m_atk_timer = max(m_atk_timer - delta, 0)

func handle_attack_request():
    var buffer = "ATK" if Input.is_action_just_pressed("ATK") else "M_ATK"
    if hitbox_anim.is_playing():
        if hitbox_anim.current_animation_length - hitbox_anim.current_animation_position > 0.125:
            return
        await hitbox_anim.animation_finished
    
    if not player.is_on_floor():
        player.velocity.y = 0
    
    if buffer == "M_ATK" and player.is_mana_break:
        return
    
    match buffer:
        #"ATK":
            #hitbox_anim.play("atk01")
            #animated_sprite_2d.play("atk0%d" % randi_range(1, 2))
            #slash_animation.play("slash0%d" % randi_range(1, 4))
            #player.on_attack.emit()
        "ATK":
            hitbox_anim.play("m_atk01")
            animated_sprite_2d.play("m_atk0%d" % randi_range(1, 2))
            slash_animation.play("m_slash0%d" % randi_range(1, 4))
            player.on_m_attack.emit()
        "M_ATK":
            return
            animated_sprite_2d.play("m_atk0%d" % randi_range(1, 2))
            Projectiles.spawn_projectile(
                Projectiles.TYPE.DEFAULT,
                projectile_spawn_point.global_position,
                player.facing * Vector2.RIGHT * 300)
    Audio.play(SLASH_SFXS.pick_random(), 0.0, 2.0)

func handle_release_attack_request():
    if not player.is_on_floor():
        player.velocity.y = 0
    $"../Rotatable/HitBox/atk01".disabled = true
    $"../Rotatable/HitBox/m_atk01".disabled = true
    hitbox_anim.play("release")
    player.on_attack.emit()

func handle_hitbox_entered(body: Node2D):
    if body is Enemy:
        Util.hitstop(0.08)
        body.velocity.x = player.facing * DEFAULT_HIT_KNOCBACK * 5
        var info: Player.AttackInfo = Player.AttackInfo.new(BASE_ATK_POWER)
        player.process_attack_value.emit(info)
        body.attacked(info.value)
        player.set_mana(player.mana + M_ATK_MANA_COST)

    player.velocity.x = player.facing * -DEFAULT_HIT_KNOCBACK
    player.velocity.x *= 1.0 if player.is_on_floor() else 0.25

func handle_release_hitbox_entered(body: Node2D):
    if body is Enemy:
        Util.hitstop(0.15)
        body.velocity.x = player.facing * DEFAULT_HIT_KNOCBACK * 8
        body.attacked(BASE_ATK_POWER * 3)

func start_m_atk():
    if not player.is_on_floor() and not can_air_m_atk: return
    can_air_m_atk = false
    in_m_atk = true

func end_m_atk():
    in_m_atk = false
