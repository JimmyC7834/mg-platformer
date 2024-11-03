extends CardData

class_name FireCard

func process_attack(value: Player.AttackInfo):
    value.value += 1
