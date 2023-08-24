extends NinePatchRect

@onready var label = $label
@onready var manabar = $manabar

func _ready():
    pass

func open(item: Item):
    label.text = "COST:\n"
    label.text += item.desc
    manabar.set_value(1, false)
