extends ChoiceDialog

onready var spell_info = $spell_info
onready var spell_info_label = $spell_info/label

var spells = []

func _ready():
    pass 

func open_with(with_spells):
    spells = with_spells
    var spell_labels = []
    for spell in spells:
        spell_labels.append(spell.name)
    set_choice_labels([spell_labels])
    .open()

func refresh_cursor():
    .refresh_cursor()
    var spell = spells[cursor_index.y]
    spell_info.visible = true
    spell_info_label.text = Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + "\nCOST: " + String(spell.cast_cost)

func close():
    spell_info.visible = false
    .close()
