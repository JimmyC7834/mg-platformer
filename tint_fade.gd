extends Node

class_name TintFade

@export var node: Node2D

func tint(color: Color, span: float = 0.5):
    node.self_modulate = color
    
    var t = create_tween()
    t.tween_property(node, "self_modulate", Color.WHITE, span)
    
