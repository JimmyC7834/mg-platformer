extends TextureProgressBar

func _ready() -> void:
    EventBus.on_player_hp_changed.connect(update)

func update(_value: float):
    max_value = Global.player.max_hp
    value = _value
