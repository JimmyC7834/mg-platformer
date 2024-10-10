extends CanvasLayer

@export var pp_camera: Camera2D

func _process(delta: float) -> void:
    if !Global.player_camera or !pp_camera: return
    pp_camera.global_transform = Global.player_camera.global_transform
