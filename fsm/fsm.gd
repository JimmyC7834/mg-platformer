class_name FSM

var state: Dictionary

func set_state(new_state: Dictionary) -> void:
    if !new_state: return
    
    if state and state.has("exit"):
        state["exit"].call()
    state = new_state
    if state and state.has("start"):
        state["start"].call()

func update(_delta) -> void:
    if state and state.has("update"): 
        state["update"].call(_delta)

func physics_update(_delta) -> void:
    if state and state.has("physics_update"):
        state["physics_update"].call(_delta)
