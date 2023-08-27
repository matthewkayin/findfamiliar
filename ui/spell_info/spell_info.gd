extends NinePatchRect

@onready var label = $label
@onready var manabar = $manabar
@onready var type_icon = $type_icon

func _ready():
    visible = false

func open(spell: Spell):
    if spell.damage_type == Spell.DamageType.PHYSICAL:
        label.text = "PHYSICAL"
    elif spell.damage_type == Spell.DamageType.MAGICAL:
        label.text = "MAGICAL"
    else:
        label.text = "STATUS"
    label.text += "\nTYPE: " + Types.NAME[spell.type] + "\n"
    label.text += "COST:\n"
    var damage_string = str(spell.power)
    var accuracy_string = str(spell.accuracy)
    if spell.damage_type == Spell.DamageType.NONE:
        damage_string = "---"
        accuracy_string = str(spell.condition_accuracy) 
    label.text += "POW:" + damage_string + " ACC:" + accuracy_string + "\n"
    label.text += spell.desc
    manabar.set_value(spell.cost, false)
    type_icon.frame = 0 if spell.damage_type == Spell.DamageType.PHYSICAL else 3
    visible = true

func close():
    visible = false
