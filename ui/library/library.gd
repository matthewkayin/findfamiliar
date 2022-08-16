extends NinePatchRect
class_name LibraryMenu

signal finished

onready var library = get_node("/root/Library")

onready var header_label = $header/label
onready var header_kp_label = $header/kp_label
onready var cursor = $list/cursor
onready var cursor_nav_up = $list/nav_up
onready var cursor_nav_down = $list/nav_down
onready var items = $list/items.get_children()
onready var prompt = $prompt
onready var yesno_prompt = $yesno_prompt
onready var info = $info
onready var learn_prompt = $learn_prompt
onready var learn_prompt_label = $learn_prompt/label

enum Mode {
    LIST,
    LEARN
}

var mode = Mode.LIST
var spells = []
var familiar = null
var familiar_spell_index = 0
var cursor_index = 0
var list_offset = 0
var just_opened = false

func _ready():
    visible = false
    prompt.connect("finished", self, "_on_prompt_finished")
    yesno_prompt.connect("finished", self, "_on_yesno_prompt_finished")

func _on_prompt_finished():
    var spell = spells[list_offset + cursor_index]
    if prompt.choice == "SET":
        familiar.spells[familiar_spell_index] = spell
        close()
    elif prompt.choice == "LEARN":
        learn_prompt.visible = true
        learn_prompt_label.text = "Spend " + String(spell.learn_cost) + " KP to learn " + spell.name + "?"
        yesno_prompt.open()

func _on_yesno_prompt_finished():
    var spell = spells[list_offset + cursor_index]
    if yesno_prompt.choice == "YES":
        familiar.spells_known.append(spell)
    learn_prompt.visible = false
    open_prompt()

func open(in_mode, with_familiar=null, spell_index=0):
    mode = in_mode

    cursor_index = 0
    list_offset = 0
    familiar_spell_index = spell_index
    just_opened = true
    prompt.visible = false
    yesno_prompt.visible = false
    info.visible = false
    learn_prompt.visible = false

    if mode == Mode.LIST:
        spells = library.spells
    elif mode == Mode.LEARN:
        familiar = with_familiar

        spells = []
        for spell in familiar.species.spells:
            if library.spells.has(spell):
                spells.append(spell)

    refresh_header()
    refresh_list()
    visible = true

func refresh_header():
    if mode == Mode.LIST:
        header_label.text = "LIRBARY\n" + String(spells.size()) + " spells known"
        header_kp_label.visible = false
    elif mode == Mode.LEARN:
        header_label.text = familiar.get_name() + "\n" + String(familiar.spells_known.size()) + " spells known"
        header_kp_label.visible = true
        header_kp_label.text = String(familiar.get_kp()) + " KP"

func refresh_list():
    for item in items:
        item.visible = false
    for i in range(0, min(10, spells.size())):
        var index = list_offset + cursor_index
        items[i].text = spells[index].name
        if mode == Mode.LEARN and familiar.spells_known.has(spells[index]):
            items[i].get_child(0).text = "KNOWN"
        else:
            items[i].get_child(0).text = String(spells[index].learn_cost) + " KP"
        items[i].visible = true
    cursor_nav_up.visible = list_offset != 0
    cursor_nav_down.visible = spells.size() > (list_offset + items.size())

func close():
    visible = false
    emit_signal("finished")

func open_spell_info():
    info.open(spells[list_offset + cursor_index])
    if mode == Mode.LEARN:
        open_prompt()

func open_prompt():
    if familiar.spells_known.has(spells[list_offset + cursor_index]):
        prompt.get_child(0).text = "SET"
    else:
        prompt.get_child(0).text = "LEARN"

func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if prompt.visible:
        return

    if Input.is_action_just_pressed("back"):
        close()
        return
    
    if Input.is_action_just_pressed("up"):
        if cursor_index > 0:
            cursor_index -= 1
        elif list_offset > 0:
            list_offset -= 1
        refresh_list()
    if Input.is_action_just_pressed("down"):
        if cursor_index < items.size() - 1:
            cursor_index += 1
        elif list_offset + items.size() < items.size():
            list_offset += 1
        refresh_list()

    if Input.is_action_just_pressed("action"):
        open_spell_info()