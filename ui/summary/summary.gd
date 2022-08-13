extends NinePatchRect

signal finished

onready var party = get_node("/root/Party")

onready var sprite = $sprite
onready var name_label = $name
onready var level = $level
onready var healthbar = $health/bar
onready var health_label = $health/value
onready var manabar = $mana/bar
onready var mana_label = $mana/value
onready var exp_label = $exp/value
onready var attack = $attack/value
onready var defense = $defense/value
onready var speed = $speed/value
onready var spell_list = $spells/list
onready var spell_labels = $spells/list.get_children()
onready var spell_info = $spells/info
onready var spell_info_label = $spells/info/label
onready var cursor = $spells/cursor
onready var switch_cursor = $spells/switch_cursor
onready var timer = $timer
onready var prompt = $summary_prompt

var familiar_index = -1
var familiar = null
var cursor_index = -1
var switch_index = -1
var allow_move_prompt = true
var just_opened = false

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    prompt.connect("finished", self, "_on_prompt_finished")
    visible = false

func _on_timeout():
    switch_cursor.visible = not switch_cursor.visible

func _on_prompt_finished():
    if prompt.choice == ChoiceDialog.NONE:
        cursor_index = -1
    elif prompt.choice == "SWITCH":
        switch_index = cursor_index
        switch_cursor.position = cursor.position
        switch_cursor.visible = true
        timer.start(0.3)

func open(at_index: int):
    familiar_index = at_index
    familiar = party.familiars[familiar_index]

    cursor.visible = false
    switch_cursor.visible = false
    spell_info.visible = false
    prompt.visible = false

    sprite.texture = load("res://battle/familiars/" + familiar.species.name.to_lower() + ".png")
    name_label.text = familiar.get_name()
    level.text = "L" + String(familiar.level)

    var health_percent = float(familiar.health) / float(familiar.max_health)
    healthbar.region_rect.size.x = int(health_percent * healthbar.texture.get_width())
    health_label.text = String(familiar.health) + " / " + String(familiar.max_health)

    var mana_percent = float(familiar.mana) / float(familiar.max_mana)
    manabar.region_rect.size.x = int(mana_percent * manabar.texture.get_width())
    mana_label.text = String(familiar.mana) + " / " + String(familiar.max_mana)

    exp_label.text = String(familiar.get_current_experience()) + " / " + String(familiar.get_experience_tnl())
    attack.text = String(familiar.attack)
    defense.text = String(familiar.defense)
    speed.text = String(familiar.speed)

    update_spell_list()

    just_opened = true
    visible = true
    print("hi")

func update_spell_list():
    for spell_label in spell_labels:
        spell_label.visible = false
    for i in range(0, familiar.spells.size()):
        spell_labels[i].text = familiar.spells[i].name
        spell_labels[i].visible = true

func open_spell_info():
    var spell = familiar.spells[cursor_index]

    spell_info_label.text = Types.NAME[spell.type] + "\nPOWER: " + String(spell.power) + " COST: " + String(spell.cast_cost) + "\n\n" + spell.desc
    spell_info.visible = true

func refresh_cursor():
    cursor.position.y = spell_list.rect_position.y + spell_labels[cursor_index].rect_position.y - 4
    cursor.visible = true

func close():
    visible = false
    emit_signal("finished")

func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if not visible:
        return

    if cursor_index == -1:
        if Input.is_action_just_pressed("back"):
            close()
        elif Input.is_action_just_pressed("left"):
            familiar_index -= 1
            if familiar_index < 0:
                familiar_index = party.familiars.size() - 1
            open(familiar_index)
        elif Input.is_action_just_pressed("right"):
            familiar_index += 1
            if familiar_index >= party.familiars.size():
                familiar_index = 0
            open(familiar_index)
        elif Input.is_action_just_pressed("action"):
            if allow_move_prompt:
                cursor_index = 0
                refresh_cursor()
                open_spell_info()
        return
    else:
        if prompt.visible:
            return
        if Input.is_action_just_pressed("back"):
            if switch_index != -1:
                end_switch()
            else:
                cursor_index = -1
                cursor.visible = false
                spell_info.visible = false
        elif Input.is_action_just_pressed("up"):
            cursor_index -= 1
            if cursor_index < 0:
                cursor_index = familiar.spells.size() - 1
            refresh_cursor()
            open_spell_info()
        elif Input.is_action_just_pressed("down"):
            cursor_index += 1
            if cursor_index >= familiar.spells.size():
                cursor_index = 0
            refresh_cursor()
            open_spell_info()
        elif Input.is_action_just_pressed("action"):
            if switch_index != -1:
                perform_switch()
                end_switch()
            else:
                prompt.open()

func perform_switch():
    var temp = familiar.spells[switch_index]
    familiar.spells[switch_index] = familiar.spells[cursor_index]
    familiar.spells[cursor_index] = temp
    update_spell_list()
    open_spell_info()

func end_switch():
    switch_index = -1
    timer.stop()
    switch_cursor.visible = false
