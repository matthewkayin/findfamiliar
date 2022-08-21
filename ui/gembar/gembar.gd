extends Control

export var flipped = false

func _ready():
    pass

func open(familiars):
    var live_count = 0
    for familiar in familiars:
        if familiar.is_living():
            live_count += 1
    var dead_count = familiars.size() - live_count
    for i in range(0, dead_count):
        set_icon(i, "killed")
    for i in range(dead_count, familiars.size()):
        set_icon(i, "filled")
    for i in range(familiars.size(), 6):
        set_icon(i, "empty")
    visible = true

func set_icon(the_index: int, status: String):
    var index = the_index
    if flipped:
        index = 5 - index
    var icon = get_child(index)
    icon.get_node("empty").visible = false
    icon.get_node("filled").visible = false
    icon.get_node("killed").visible = false
    if status == "empty":
        icon.get_node("empty").visible = true
    elif status == "filled":
        icon.get_node("filled").visible = true
    elif status == "killed":
        icon.get_node("filled").visible = true
        icon.get_node("killed").visible = true
