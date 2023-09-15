extends NinePatchRect

@onready var label = $label
@onready var damage_type_icon = $damage_type_icon
@onready var spell_type_icon = $spell_type_icon

func _ready():
    visible = false
    get_parent().updated_cursor.connect(_on_spell_chooser_update_cursor)
    get_parent().closed.connect(close)

func _on_spell_chooser_update_cursor():
    open(get_node("/root/player_party").get_familiar(0).spells[get_parent().cursor_index.x + (2 * get_parent().cursor_index.y)])

func open(spell: Spell):
    damage_type_icon.frame = 0 if spell.damage_type == Spell.DamageType.PHYSICAL else 1
    spell_type_icon.frame = spell.type

    var damage_string = str(spell.power)
    var accuracy_string = str(spell.accuracy)
    if spell.damage_type == Spell.DamageType.NONE:
        damage_string = "---"
        accuracy_string = str(spell.condition_accuracy) 
    label.text = "POW: " + damage_string + "\nACC: " + accuracy_string + "\n"
    visible = true

func close():
    visible = false
