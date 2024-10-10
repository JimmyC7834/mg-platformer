extends Area2D

class_name VisionArea

signal on_player_entered()

func _ready() -> void:
    body_entered.connect(fire)

func fire(body: Node2D):
    if body is Player:
        on_player_entered.emit()
