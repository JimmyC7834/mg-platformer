extends Node2D

var insts: Array[CardInst] = []

func _ready():
    for c in get_children():
        if c is CardInst:
            insts.append(c)
    
    EventBus.on_player_cards_activition_changed.connect(update)

func update(cursor: int):
    for i in range(len(insts)):
        insts[i].visible = false
        
        if i < cursor:
            insts[i].vSpeed += i * 0.25 * randf() / (cursor + 1)
            insts[i].tOffset = i * 2 * PI / (cursor + 1)
            insts[i].visible = true
