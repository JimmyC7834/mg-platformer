extends CharacterBody2D

class_name Enemy

const LIMIT_SPEED_Y: int = 1200
const GRAVITY: int = 2100

@export var data: EnemyData

signal on_attacked()
signal on_damaged()
signal on_death()

func _ready() -> void:
    if data:
        data = data.duplicate(true)

func attacked(value: float):
    take_damage(value)
    on_attacked.emit()

func take_damage(value: float):
    data.hp -= value
    on_damaged.emit()
    if data.hp <= 0:
        on_death.emit()

func apply_gravity(delta):
    if velocity.y <= LIMIT_SPEED_Y:
        velocity.y += GRAVITY * delta
    else:
        velocity.y = LIMIT_SPEED_Y
