extends Control

@onready var spheres = get_children()

func _ready():
    pass

func set_value(value: int, show_empty: bool):
    var mana_remaining = value
    for i in range(0, 3):
        if mana_remaining >= 1:
            spheres[i].frame = 2
            spheres[i].visible = true
            mana_remaining -= 1
        else:
            if show_empty:
                spheres[i].visible = true
                spheres[i].frame = 0
            else:
                spheres[i].visible = false