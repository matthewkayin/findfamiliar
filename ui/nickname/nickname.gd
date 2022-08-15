extends NinePatchRect

signal finished

onready var familiar_sprite = $familiar_sprite
onready var dialog = $dialog
onready var yes_no_prompt = $yesno_prompt
onready var typing_prompt = $typing_prompt
onready var typing_input = $typing_input
onready var typing_input_chars = $typing_input/name_characters.get_children()

var familiar = null
var input_value = ""
var typing_prompt_just_opened = false

func _ready():
    yes_no_prompt.visible = false
    typing_prompt.visible = false
    typing_input.visible = false

func _input(event):
    if not typing_prompt.visible or typing_prompt_just_opened:
        return
    if event is InputEventKey and event.pressed:
        if event.scancode >= KEY_A and event.scancode <= KEY_Z:
            var new_char = char(event.scancode)
            if not Input.is_key_pressed(KEY_SHIFT):
                new_char = new_char.to_lower()
            if input_value.length() < 10:
                input_value += new_char
        elif event.scancode == KEY_SPACE:
            if input_value.length() < 10:
                input_value += " "
        elif event.scancode == KEY_BACKSPACE:
            if input_value.length() != 0:
                input_value.erase(input_value.length() - 1, 1)
        elif event.scancode == KEY_ENTER:
            familiar.nickname = input_value

            typing_prompt.visible = false
            typing_input.visible = false
            visible = false
            emit_signal("finished")
        refresh_typing_input()

func open(with_familiar: Familiar):
    familiar = with_familiar

    input_value = ""

    yes_no_prompt.visible = false
    typing_prompt.visible = false
    typing_input.visible = false

    familiar_sprite.texture = load("res://battle/familiars/" + familiar.species.name.to_lower() + ".png")

    dialog.clear_on_finish = false
    dialog.hide_on_close = false
    dialog.open_and_split("Give a name to the captured " + familiar.species.name + "?")
    visible = true

    yield(dialog, "finished")

    yes_no_prompt.open()
    yield(yes_no_prompt, "finished")
    dialog.visible = false
    if yes_no_prompt.choice == "NO":
        visible = false
        emit_signal("finished")
    elif yes_no_prompt.choice == "YES":
        typing_prompt.visible = true
        typing_input.visible = true
        typing_prompt_just_opened = true
        refresh_typing_input()

func refresh_typing_input():
    typing_input.visible = true
    for i in range(0, typing_input_chars.size()):
        if i < input_value.length():
            typing_input_chars[i].text = input_value[i]
            typing_input_chars[i].rect_position.y = 12
            continue
        else:
            typing_input_chars[i].text = "-"
            if i == input_value.length():
                typing_input_chars[i].rect_position.y = 12 + 8
            else:
                typing_input_chars[i].rect_position.y = 12 + 4

func _process(_delta):
    if typing_prompt_just_opened:
        typing_prompt_just_opened = false
