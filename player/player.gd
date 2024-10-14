extends CharacterBody2D

class_name Player

const MANA_DECAY_RATE: float = 4
const HURT_KNOCKBACK: float = 100.0

const DASH_SPAN: float = 0.25
const DASH_SPEED: float = 400.0

var mana: float = 0

var axis: Vector2
var facing: int = 1

var invincible: bool = false
var is_dashing: bool = false

signal request_perform_attack()
signal request_perform_release()
signal request_release_attack()

signal on_attack()
signal process_attack_value(value: AttackInfo)
signal on_m_attack()
signal process_m_attack_value(value: AttackInfo)

signal on_attacked()
signal on_damaged()

func _ready() -> void:
    Global.player = self

func _physics_process(delta: float) -> void:
    set_mana(max(0, mana - MANA_DECAY_RATE * delta))
    EventBus.on_player_mana_changed.emit(mana)

func attacked_by(e: Enemy):
    if invincible: return
    take_damage()
    on_attacked.emit()

func take_damage():
    on_damaged.emit()

func set_mana(value: float):
    mana = max(0, value)

class AttackInfo:
    var value: float = 0.0
    
    func _init(value: float):
        self.value = value
