extends NinePatchRect

signal finished

onready var party = get_node("/root/Party")

onready var sprite = $sprite
onready var name_label = $name
onready var level = $level
onready var healthbar = $health/bar
onready var health_label = $health/value
onready var manabar = $mana/bar
onready var expbar = $exp/bar
onready var mana_label = $mana/value
onready var attack = $attack/value
onready var defense = $defense/value
onready var speed = $speed/value
onready var spell_list = $spells/list
onready var spell_labels = $spells/list.get_children()
onready var spell_info = $spells/info
onready var cursor = $spells/cursor
onready var switch_cursor = $spells/switch_cursor
onready var timer = $timer
onready var prompt = $prompt
onready var move_order_prompt = $move_order_prompt
onready var conditions = $conditions
onready var spells_known_list = $spells/spells_known_list
onready var spells_known_cursor = $spells/spells_known_list/cursor
onready var spells_known_nav_up_cursor = $spells/spells_known_list/nav_up
onready var spells_known_nav_down_cursor = $spells/spells_known_list/nav_down
onready var spells_known_list_list = $spells/spells_known_list/list
onready var spells_known_labels = $spells/spells_known_list/list.get_children()
onready var library = get_parent().get_parent().get_node("library")

var familiar_index = -1
var familiar = null
var cursor_index = -1
var switch_index = -1
var allow_move_prompt = true
var just_opened = false
var spells_known_cursor_index = 0
var spells_known_list_offset = 0

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    prompt.connect("finished", self, "_on_prompt_finished")
    move_order_prompt.connect("finished", self, "_on_move_order_prompt_finished")
    library.connect("finished", self, "_on_library_finished")
    visible = false

func _on_library_finished():
    if not visible:
        return
    just_opened = true
    prompt.open()

func _on_timeout():
    switch_cursor.visible = not switch_cursor.visible

func _on_prompt_finished():
    if prompt.choice == ChoiceDialog.NONE:
        cursor_index = -1
    elif prompt.choice == "SET":
        cursor_index = 0
        refresh_cursor()
        open_spell_info()
    elif prompt.choice == "LEARN":
        library.open(LibraryMenu.Mode.LEARN, familiar)

func _on_move_order_prompt_finished():
    if move_order_prompt.choice == ChoiceDialog.NONE:
        prompt.open()
    elif move_order_prompt.choice == "SWITCH":
        switch_index = cursor_index
        switch_cursor.position = cursor.position
        switch_cursor.visible = true
        timer.start(0.3)
    elif move_order_prompt.choice == "SET":
        open_spells_known()

func open_spells_known():
    spells_known_cursor_index = 0
    spells_known_list_offset = 0
    refresh_spells_known()

func refresh_spells_known():
    for child in spells_known_labels:
        child.visible = false
    if spells_known_list_offset + spells_known_labels.size() > familiar.spells_known.size():
        spells_known_list_offset = 0
    for i in range(0, min(familiar.spells_known.size(), spells_known_labels.size())):
        spells_known_labels[i].text = familiar.spells_known[spells_known_list_offset + i].name
        spells_known_labels[i].visible = true
    spells_known_cursor.position.y = spells_known_list_list.rect_position.y + spells_known_labels[spells_known_cursor_index].rect_position.y - 2.5
    spells_known_cursor.visible = true
    spells_known_nav_up_cursor.visible = spells_known_list_offset != 0
    spells_known_nav_down_cursor.visible = spells_known_list_offset + spells_known_labels.size() < familiar.spells_known.size()
    spell_info.open(familiar.spells_known[spells_known_list_offset + spells_known_cursor_index])
    spells_known_list.visible = true

func close_spells_known():
    spells_known_list.visible = false
    update_spell_list()
    open_spell_info()

func open(at_index: int):
    familiar_index = at_index
    familiar = party.familiars[familiar_index]

    cursor.visible = false
    switch_cursor.visible = false
    spell_info.visible = false
    prompt.visible = false
    spells_known_list.visible = false

    sprite.texture = load("res://battle/familiars/" + familiar.species.name.to_lower() + ".png")
    name_label.text = familiar.get_name()
    level.text = "L" + String(familiar.level)

    var health_percent = float(familiar.health) / float(familiar.max_health)
    healthbar.region_rect.size.x = int(health_percent * healthbar.texture.get_width())
    health_label.text = String(familiar.health) + " / " + String(familiar.max_health)

    var mana_percent = float(familiar.mana) / float(familiar.max_mana)
    manabar.region_rect.size.x = int(mana_percent * manabar.texture.get_width())
    mana_label.text = String(familiar.mana) + " / " + String(familiar.max_mana)

    var exp_percent = float(familiar.get_current_experience()) / float(familiar.get_experience_tnl())
    expbar.region_rect.size.x = int(exp_percent * expbar.texture.get_width())

    attack.text = String(familiar.attack)
    defense.text = String(familiar.defense)
    speed.text = String(familiar.speed)

    for child in conditions.get_children():
        child.visible = false
    for i in range(0, familiar.conditions.size()):
        var condition = familiar.conditions[i]
        var condition_name = Conditions.Condition.keys()[condition.type].to_lower()
        var existing_condition_icon = conditions.get_node_or_null(condition_name)
        if existing_condition_icon != null:
            existing_condition_icon.position = Vector2(i * 24, 0)
            existing_condition_icon.visible = true
        else:
            var new_icon = Sprite.new()
            new_icon.texture = load("res://ui/healthbar/status_icons/" + condition_name + ".png")
            conditions.add_child(new_icon)
            new_icon.position = Vector2(i * 24, 0)
    for child in conditions.get_children():
        if not child.visible:
            child.queue_free()

    update_spell_list()

    just_opened = true
    visible = true

func update_spell_list():
    for i in range(0, familiar.spells.size()):
        if familiar.spells[i] == null:
            spell_labels[i].text = ""
        else:
            spell_labels[i].text = familiar.spells[i].name

func open_spell_info():
    var spell
    if cursor_index >= familiar.spells.size():
        spell = null
    else:
        spell = familiar.spells[cursor_index]
    spell_info.open(spell)

func refresh_cursor():
    cursor.position.y = spell_list.rect_position.y + spell_labels[cursor_index].rect_position.y - 4
    cursor.visible = true

func close():
    visible = false
    emit_signal("finished")

func _process(_delta):
    if library.visible:
        return
    if just_opened:
        just_opened = false
        return
    if not visible:
        return

    if spells_known_list.visible:
        if Input.is_action_just_pressed("back"):
            close_spells_known()
            return
        if Input.is_action_just_pressed("up"):
            if spells_known_cursor_index > 0:
                spells_known_cursor_index -= 1
            elif spells_known_list_offset > 0:
                spells_known_list_offset -= 1
            refresh_spells_known()
            return
        if Input.is_action_just_pressed("down"):
            if spells_known_cursor_index < spells_known_labels.size() - 1:
                spells_known_cursor_index += 1
            elif spells_known_list_offset + spells_known_labels.size() - 1 < familiar.spells_known.size() - 1:
                spells_known_list_offset += 1
            refresh_spells_known()
            return
        if Input.is_action_just_pressed("action"):
            var set_spell = familiar.spells_known[spells_known_list_offset + spells_known_cursor_index]
            var set_spell_index = familiar.spells.find(set_spell)
            if set_spell_index != -1:
                familiar.spells[set_spell_index] = null
            familiar.spells[cursor_index] = set_spell
            close_spells_known()
            return
        return

    if cursor_index == -1:
        if prompt.visible:
            return
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
                prompt.open()
        return
    else:
        if move_order_prompt.visible:
            return
        if Input.is_action_just_pressed("back"):
            if switch_index != -1:
                end_switch()
            else:
                cursor_index = -1
                cursor.visible = false
                spell_info.visible = false
                prompt.open()
        elif Input.is_action_just_pressed("up"):
            cursor_index -= 1
            if cursor_index < 0:
                cursor_index = familiar.spells.size() - 1
            refresh_cursor()
            open_spell_info()
        elif Input.is_action_just_pressed("down"):
            cursor_index += 1
            if cursor_index >= 4:
                cursor_index = 0
            refresh_cursor()
            open_spell_info()
        elif Input.is_action_just_pressed("action"):
            if switch_index != -1:
                perform_switch()
                end_switch()
            else:
                move_order_prompt.open()

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
