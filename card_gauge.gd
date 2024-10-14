extends HBoxContainer

var progress_bars: Array[TextureProgressBar] = []

func _ready() -> void:
    for c in get_children():
        if c is TextureProgressBar:
            progress_bars.append(c)
    
    EventBus.on_player_cards_updated.connect(update)

func update(playerCards: PlayerCards):
    for i in range(len(progress_bars)):
        progress_bars[i].value = playerCards.card_gauge if i == playerCards.cursor else \
                                 100 if i < len(playerCards.cards) else 0
        progress_bars[i].visible = i < len(playerCards.cards)
