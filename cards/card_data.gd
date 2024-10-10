extends Resource

class_name CardData

@export var sprite: Texture2D
@export var displayName: StringName

var player: Player
var enabled: bool = false

func register(_player: Player):
    player = _player
    _register()

func _register():
    pass
