extends Node

func wait(span: float) -> Signal:
    return get_tree().create_timer(span).timeout

func hitstop(span: float):
    Engine.time_scale = 0.0001
    await get_tree().create_timer(span, true, false, true).timeout
    Engine.time_scale = 1
