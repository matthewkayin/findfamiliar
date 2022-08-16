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
        if spell == null:
            spell_labels.append("")
        else:
            spell_labels.append(spell.name)
    set_choice_labels([spell_labels])
    for i in range(0, spells.size()):
        if choices[0][i].text == "":
            continue
        if spells[i].cast_cost > mana:
            choices[0][i].set("custom_colors/font_color", Color("#ac3232"))
        else:
            choices[0][i].set("custom_colors/font_color", Color("#000000"))
    .open()

func move_cursor(direction: Vector2):
    # If there are no spells equipped, don't show the cursor
    cursor.visible = false
    for spell in spells:
        if spell != null:
            cursor.visible = true
            break
    if not cursor.visible:
        return

    .move_cursor(direction)
    while spells[cursor_index.y] == null:
        .move_cursor(direction)

func refresh_cursor():
    .refresh_cursor()
    var spell = spells[cursor_index.y]
    spell_info.visible = true
    if spell == null:
        spell_info_label.text = ""
    else:
        spell_info_label.text = Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + "\nCOST: " + String(spell.cast_cost)

func close():
    spell_info.visible = false
    .close()

func choose():
    if spells[cursor_index.y] == null:
        return
    if spells[cursor_index.y].cast_cost > mana:
        return
    .choose()
