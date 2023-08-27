extends NinePatchRect

@onready var label = $label
@onready var type_icon = $type_icon

func _ready():
    visible = false
    get_parent().updated_cursor.connect(_on_spell_chooser_update_cursor)
    get_parent().closed.connect(close)

func _on_spell_chooser_update_cursor():
    open(get_node("/root/player_party").familiars[0].spells[get_parent().cursor_index.y])

func open(spell: Spell):
    if spell.damage_type == Spell.DamageType.PHYSICAL:
        label.text = "PHYSICAL"
    elif spell.damage_type == Spell.DamageType.MAGICAL:
        label.text = "MAGICAL"
    else:
        label.text = "STATUS"
    type_icon.frame = 0 if spell.damage_type == Spell.DamageType.PHYSICAL else 3

    label.text += "\nTYPE: " + Types.NAME[spell.type] + "\n"
    var damage_string = str(spell.power)
    var accuracy_string = str(spell.accuracy)
    if spell.damage_type == Spell.DamageType.NONE:
        damage_string = "---"
        accuracy_string = str(spell.condition_accuracy) 
    label.text += "POW:" + damage_string + " ACC:" + accuracy_string + "\n"
    label.text += spell.desc
    visible = true

func close():
    visible = false
