extends NinePatchRect

onready var label = $label

func _ready():
    pass 

func close(): 
    visible = false

func open(spell):
    if spell == null:
        label.text = ""
    else:
        label.text = Types.NAME[spell.type] + String(spell.cast_cost) + " MP\nPOWER " + String(spell.power) 
    visible = true