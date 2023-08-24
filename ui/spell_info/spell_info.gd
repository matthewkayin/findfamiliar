extends NinePatchRect

@onready var label = $label
@onready var manabar = $manabar

func _ready():
    visible = false

func open(spell: Spell):
    label.text = "TYPE: " + Types.NAME[spell.type] + "\n"
    label.text += "COST:\n"
    label.text += "POW:" + str(spell.power) + " ACC:" + str(spell.accuracy) + "\n"
    if spell.damage_type == Spell.DamageType.PHYSICAL:
        label.text += "PHYSICAL DAMAGE\n"
    elif spell.damage_type == Spell.DamageType.MAGICAL:
        label.text += "MAGICAL DAMAGE\n"
    else:
        label.text += "NO DAMAGE\n"
    label.text += spell.desc
    manabar.set_value(spell.cost, false)
    visible = true

func close():
    visible = false
