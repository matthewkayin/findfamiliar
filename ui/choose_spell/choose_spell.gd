extends ChoiceDialog

onready var spell_info = $spell_info
onready var spell_info_label = $spell_info/label

var spells = []
var mana: int

func _ready():
    pass 

func open_with(with_spells, and_mana: int):
    spells = with_spells
    mana = and_mana
    var spell_labels = []
    for spell in spells:
        spell_labels.append(spell.name)
    set_choice_labels([spell_labels])
    for i in range(0, spells.size()):
        if not choices[0][i].visible:
            return
        if spells[i].cast_cost > mana:
            choices[0][i].set("custom_colors/font_color", Color("#ac3232"))
        else:
            choices[0][i].set("custom_colors/font_color", Color("#000000"))
    .open()

func refresh_cursor():
    .refresh_cursor()
    var spell = spells[cursor_index.y]
    spell_info.visible = true
    spell_info_label.text = Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + "\nCOST: " + String(spell.cast_cost)

func close():
    spell_info.visible = false
    .close()

func choose():
    if spells[cursor_index.y].cast_cost > mana:
        return
    .choose()
