extends NinePatchRect
class_name PartyMenu

signal finished

onready var party = get_node("/root/Party")

onready var cursor = $cursor
onready var healthbars = $choices/healthbars.get_children()
onready var exit = $choices/exit
onready var prompt = $prompt
onready var prompt_noswitch = $prompt_noswitch
onready var switch_cursor = $switch_cursor
onready var timer = $timer
onready var summary = $summary

enum State {
    CLOSED,
    CHOOSING,
    SUBMENU,
    SWITCH
}

enum Context {
    DEFAULT,
    ITEM,
    SUMMON
}

var cursor_index = 0
var state = State.CLOSED
var context = Context.DEFAULT
var switch_index
var just_opened = false
var allow_back = true

func _ready():
    visible = false
    prompt.connect("finished", self, "_on_prompt_finish")
    prompt_noswitch.connect("finished", self, "_on_prompt_noswitch_finish")
    timer.connect("timeout", self, "_on_timer_timeout")
    summary.connect("finished", self, "_on_summary_finish")

func _on_timer_timeout():
    switch_cursor.visible = not switch_cursor.visible

func _on_prompt_finish():
    if prompt.choice == ChoiceDialog.NONE:
        state = State.CHOOSING
    elif prompt.choice == "SUMMARY":
        open_summary()
    elif prompt.choice == "SWITCH":
        if context == Context.SUMMON:
            switch_index = cursor_index
            close()
        else:
            begin_switch()

func _on_prompt_noswitch_finish():
    if prompt_noswitch.choice == ChoiceDialog.NONE:
        state = State.CHOOSING
    elif prompt_noswitch.choice == "SUMMARY":
        open_summary()

func _on_summary_finish():
    state = State.CHOOSING

func open_summary():
    if context == Context.SUMMON:
        summary.allow_move_prompt = false
    summary.open(cursor_index)

func begin_switch():
    switch_index = cursor_index
    switch_cursor.position = cursor.position
    timer.start(0.3)
    state = State.SWITCH

func end_switch():
    timer.stop()
    switch_cursor.visible = false
    state = State.CHOOSING

func perform_switch():
    party.swap_familiars(switch_index, cursor_index)
    refresh_healthbars()
    end_switch()

func refresh_healthbars():
    for healthbar in healthbars:
        healthbar.visible = false
    for i in range(0, party.familiars.size()):
        healthbars[i].set_familiar(party.familiars[i])
        healthbars[i].visible = true

func open():
    refresh_healthbars()
    cursor_index = 0
    switch_index = -1
    refresh_cursor()
    visible = true
    just_opened = true
    state = State.CHOOSING

func close():
    visible = false
    state = State.CLOSED
    emit_signal("finished")

func refresh_cursor():
    if cursor_index < party.familiars.size():
        cursor.position = Vector2(12, healthbars[cursor_index].rect_position.y + 3)
    else:
        cursor.position = Vector2(12, exit.rect_position.y)

func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if summary.visible:
        return
    if state != State.CHOOSING and state != State.SWITCH:
        return

    if allow_back and (Input.is_action_just_pressed("back") or (Input.is_action_just_pressed("action") and cursor_index == party.familiars.size())):
        if state == State.CHOOSING:
            close()
        elif state == State.SWITCH:
            end_switch()
        return

    if Input.is_action_just_pressed("action"):
        if state == State.SWITCH:
            perform_switch()
        elif context == Context.ITEM:
            pass
        elif context == Context.SUMMON and (cursor_index == 0 or not party.familiars[cursor_index].is_living()):
            prompt_noswitch.open()
            state = State.SUBMENU
        else:
            prompt.open()
            state = State.SUBMENU

    if Input.is_action_just_pressed("up"):
        cursor_index -= 1
        if cursor_index < 0:
            cursor_index = party.familiars.size()
        refresh_cursor()
    if Input.is_action_just_pressed("down"):
        cursor_index += 1
        if cursor_index > party.familiars.size():
            cursor_index = 0
        refresh_cursor()
