extends CardData

class_name WindyCard

func _register():
    player.on_m_attack.connect(effect)

func effect():
    if not enabled: return
    if player.is_on_floor(): return
    player.velocity.y -= 400
