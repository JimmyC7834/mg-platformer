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
        print(cards[cursor], " enabled")
        cursor = (cursor + 1)
        EventBus.on_player_cards_activition_changed.emit(cursor)
