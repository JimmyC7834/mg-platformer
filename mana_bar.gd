extends TextureProgressBar

func _ready() -> void:
    EventBus.on_player_mana_changed.connect(update)

func update(mana_value: float):
    value = mana_value
