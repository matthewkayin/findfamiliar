extends NinePatchRect
class_name LibraryMenu

signal finished

onready var library = get_node("/root/Library")

onready var header_label = $header/label
onready var header_kp_label = $header/kp_label
onready var cursor = $list/cursor
onready var cursor_nav_up = $list/nav_up
onready var cursor_nav_down = $list/nav_down
onready var items_box = $list/items
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
var cursor_index = 0
var list_offset = 0
var just_opened = false

func _ready():
    visible = false
    prompt.connect("finished", self, "_on_prompt_finished")
    yesno_prompt.connect("finished", self, "_on_yesno_prompt_finished")

func _on_prompt_finished():
    just_opened = true
    var spell = spells[list_offset + cursor_index]
    if prompt.choice == "LEARN":
        learn_prompt.visible = true
        learn_prompt_label.text = "Spend " + String(spell.learn_cost) + " KP to learn " + spell.name + "?"
        yesno_prompt.open()
    else:
        info.visible = false

func _on_yesno_prompt_finished():
    learn_prompt.visible = false
    just_opened = true

    var spell = spells[list_offset + cursor_index]
    if yesno_prompt.choice == "YES":
        familiar.spells_known.append(spell)
        info.visible = false
        refresh_header()
        refresh_list()
    elif yesno_prompt.choice == "NO":
        open_prompt()

func open(in_mode, with_familiar=null):
    mode = in_mode

    cursor_index = 0
    list_offset = 0
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
        var index = list_offset + i
        items[i].text = spells[index].name
        if mode == Mode.LEARN:
            if familiar.spells_known.has(spells[index]):
                items[i].get_child(0).text = "KNOWN"
                items[i].get_child(0).set("custom_colors/font_color", Color("#000000"))
            else:
                items[i].get_child(0).text = String(spells[index].learn_cost) + " KP"
                if familiar.get_kp() < spells[index].learn_cost:
                    items[i].get_child(0).set("custom_colors/font_color", Color("#ac3232"))
        else:
            items[i].get_child(0).text = String(spells[index].learn_cost) + " KP"
        items[i].visible = true
    cursor_nav_up.visible = list_offset != 0
    cursor_nav_down.visible = spells.size() > (list_offset + items.size())
    cursor.position.y = items_box.rect_position.y + items[cursor_index].rect_position.y - 2.5
    cursor.visible = true

func close():
    visible = false
    emit_signal("finished")

func open_spell_info():
    info.open(spells[list_offset + cursor_index])
    if mode == Mode.LEARN:
        open_prompt()

func open_prompt():
    if not familiar.spells_known.has(spells[list_offset + cursor_index]) and familiar.get_kp() >= spells[list_offset + cursor_index].learn_cost:
        prompt.open()

func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if prompt.visible or yesno_prompt.visible:
        return
    if not visible:
        return

    if Input.is_action_just_pressed("back"):
        if info.visible:
            info.visible = false
        else:
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
