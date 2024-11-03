extends Node

class_name TintFade

@export var node: Node

func tint(color: Color, span: float = 0.5):
    if node is Node2D or node is CanvasItem:
        node.self_modulate = color
        
        var t = create_tween()
        t.tween_property(node, "self_modulate", Color.WHITE, span)
    
