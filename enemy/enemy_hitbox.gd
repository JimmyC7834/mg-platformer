extends Area2D

class_name EnemyHitbox

@export var parent: Enemy

func _ready() -> void:
    if parent is Enemy:
        body_entered.connect(handle_hit)

func handle_hit(body: Node2D):
    if body is Player:
        body.attacked_by(parent)
