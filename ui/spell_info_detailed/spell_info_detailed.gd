extends NinePatchRect

onready var label = $label

func _ready():
    visible = false

func open(spell):
    if spell == null:
        label.text = ""
    else:
        label.text = spell.name + "\nTYPE: " + Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + " COST: " + String(spell.cast_cost) + "\n\n" + spell.desc
    visible = true

func close():
    visible = false
