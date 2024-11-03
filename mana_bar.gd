extends TextureProgressBar

func _ready() -> void:
    EventBus.on_player_mana_changed.connect(update)
    EventBus.on_player_mana_break.connect(check_mana_break_tint)

func update(mana_value: float):
    value = mana_value

func check_mana_break_tint():
    if Global.player.is_mana_break:
        $"TintFade".tint(Color.BLUE_VIOLET, 0.35)
        await Util.wait(0.35)
        check_mana_break_tint()
