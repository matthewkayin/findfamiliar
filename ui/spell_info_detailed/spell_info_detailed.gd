extends NinePatchRect

onready var label = $label

func _ready():
    visible = false

func open(spell):
    if spell == null:
        label.text = ""
    else:
        label.text = spell.name + " (" + Types.NAME[spell.type] + ")\nCOST " + String(spell.cast_cost) + " MP\nPOWER " + String(spell.power) + " ACCURACY " + String(spell.accuracy) + "\n\n" + spell.desc
    visible = true

func close():
    visible = false
