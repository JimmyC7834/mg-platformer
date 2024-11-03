extends Area2D

class_name Projectile

@export var damage: float = 1.0
@export var velocity: Vector2
@export var span: float = .75

func _ready():
    body_entered.connect(handle_body_enter)

func _physics_process(delta: float) -> void:
    global_position += velocity * delta
    span -= delta
    if span <= 0:
        queue_free()

func handle_body_enter(body: Node2D):
    if body is Enemy:
        body.attacked(damage)
    queue_free()
