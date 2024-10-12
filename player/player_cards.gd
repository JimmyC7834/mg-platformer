extends Node

const CARD_COST: float = 100.0

@export var cards: Array[CardData]

var card_gauge: float = 0
var cursor: int = 0

var player: Player

func _ready() -> void:
    if get_parent() is Player:
        player = get_parent()
        player.on_m_attack.connect(handle_m_attack)
        player.request_perform_release.connect(handle_release)
        
        for c in cards:
            c.register(player)
    
func handle_m_attack():
    if cards.is_empty(): return
    if cursor == len(cards): return
    if cards[cursor].enabled: return
    
    card_gauge += 150
    if card_gauge >= CARD_COST:
        card_gauge -= CARD_COST
        cards[cursor].enabled = true
        cursor += 1
        EventBus.on_player_cards_activition_changed.emit(cursor)

func handle_release():
    if cards.is_empty(): return
    if cursor == 0: return

    player.set_mana(player.mana - 50)
    cursor -= 1
    cards[cursor].enabled = false

    EventBus.on_player_cards_activition_changed.emit(cursor)
    player.request_release_attack.emit()
