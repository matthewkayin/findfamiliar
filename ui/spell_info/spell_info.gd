extends NinePatchRect

onready var label = $label

func _ready():
    pass 

func close(): 
    visible = false

func open(spell: Spell):
    label.text = Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + "\nCOST: " + String(spell.cast_cost)
    visible = true