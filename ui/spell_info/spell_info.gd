extends NinePatchRect

@onready var label = $label
@onready var manabar = $manabar

func _ready():
    visible = false

func open(spell: Spell):
    label.text = "TYPE: " + Types.NAME[spell.type] + "\n"
    label.text += "COST:\n"
    var damage_string = str(spell.power)
    var accuracy_string = str(spell.accuracy)
    if spell.damage_type == Spell.DamageType.NONE:
        damage_string = "---"
        accuracy_string = str(spell.condition_accuracy) 
    label.text += "POW:" + damage_string + " ACC:" + accuracy_string + "\n"
    if spell.damage_type == Spell.DamageType.PHYSICAL:
        label.text += "PHYSICAL DAMAGE\n"
    elif spell.damage_type == Spell.DamageType.MAGICAL:
        label.text += "MAGICAL DAMAGE\n"
    label.text += spell.desc
    manabar.set_value(spell.cost, false)
    visible = true

func close():
    visible = false
