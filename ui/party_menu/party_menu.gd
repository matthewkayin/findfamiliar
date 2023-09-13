extends NinePatchRect
class_name PartyMenu

@onready var party: Party = get_node("/root/player_party")

signal finished
signal interpolate_finished
signal clear_warning

@onready var group = [$one, $two, $three, $four]
@onready var minis = [$one/mini, $two/mini, $three/mini, $four/mini]
@onready var name_label = [$one/name_label, $two/name_label, $three/name_label, $four/name_label]
@onready var level_label = [$one/level_label, $two/level_label, $three/level_label, $four/name_label]
@onready var health_cluster = [$one/health, $two/health, $three/health, $four/health]
@onready var healthbar = [$one/health/healthbar, $two/health/healthbar, $three/health/healthbar, $four/health/healthbar]
@onready var health_amount = [$one/health/health_amount, $two/health/health_amount, $three/health/health_amount, $four/health/health_amount]
@onready var exp_cluster = [$one/exp, $two/exp, $three/exp, $four/exp]
@onready var expbar = [$one/exp/expbar, $two/exp/expbar, $three/exp/expbar, $four/exp/expbar]
@onready var condition = [$one/condition, $two/condition, $three/condition, $four/condition]
@onready var cursor = $cursor
@onready var timer = $timer
@onready var action_menu = $actions
@onready var action_status_only_menu = $actions_status_only
@onready var dialog = $dialog
@onready var summary = $ui/summary

const HEALTHBAR_COLOR_GREEN = Color8(0, 184, 0, 255)
const HEALTHBAR_COLOR_YELLOW = Color8(248, 168, 0, 255)
const HEALTHBAR_COLOR_RED = Color8(248, 0, 0, 255)

enum Mode {
    STATUS,
    SWITCH,
    SWITCH_REQUIRED,
    ITEM,
    ITEM_REVIVE,
    EXP
}

var mode: Mode

var cursor_index = Vector2i(0, 0)
var allow_back: bool = true
var is_finished: bool = false
var choice: int = -1
var just_opened: bool = false

var healthbar_max_width: int
var expbar_max_width: int
var displayed_health: Array[float] = [0.0, 0.0, 0.0]
var is_interpolating: bool = false
var interpolate_value: float = 0.0

func _ready():
    visible = false
    healthbar_max_width = healthbar[0].size.x
    expbar_max_width = expbar[0].size.x
    timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
    if exp_cluster[0].visible:
        for i in range(0, party.familiars.size()):
            if party.familiars[i].is_living():
                minis[i].frame = 1 if minis[i].frame == 0 else 0
    else:
        if party.familiars[cursor_index.y].is_living():
            minis[cursor_index.y].frame = 1 if minis[cursor_index.y].frame == 0 else 0

func start_animation():
    timer.start(0.2)

func is_open():
    return visible

func close():
    visible = false
    timer.stop()

func open(in_mode: Mode):
    mode = in_mode
    allow_back = mode != Mode.SWITCH_REQUIRED and mode != Mode.EXP
    cursor_index = Vector2i(0, 0)
    is_finished = false
    just_opened = true
    action_menu.close()

    for i in range(0, 4):
        if i >= party.familiars.size():
            group[i].visible = false
            continue

        name_label[i].text = party.familiars[i].get_display_name()
        level_label[i].text = "Lv" + str(party.familiars[i].level)
        displayed_health[i] = party.familiars[i].health
        minis[i].texture = load("res://battle/sprites/minis/" + party.familiars[i].species.name.to_lower().replace(" ", "-") + ".png")
        if party.familiars[i].condition != Condition.Type.NONE:
            condition[i].frame = Condition.INFO[party.familiars[i].condition].icon_frame

        health_cluster[i].visible = mode != Mode.EXP
        condition[i].visible = party.familiars[i].condition != Condition.Type.NONE and mode != Mode.EXP
        exp_cluster[i].visible = mode == Mode.EXP
        cursor.visible = mode != Mode.EXP

        group[i].visible = true
    start_animation()
    refresh()
    update_cursor()
    visible = true

    if mode == Mode.EXP:
        dialog.clear()
        var fade_in_tween = get_tree().create_tween()
        fade_in_tween.tween_interval(0.25)
        await fade_in_tween.finished

func refresh():
    for i in range(0, 3):
        if i >= party.familiars.size():
            continue

        if health_cluster[i].visible:
            var health: float = displayed_health[i]
            if is_interpolating:
                var health_difference = party.familiars[i].health - displayed_health[i]
                health += health_difference * interpolate_value
            var health_percent: float = health / float(party.familiars[i].max_health)
            health_amount[i].text = str(int(health)) + "/" + str(party.familiars[i].max_health)
            healthbar[i].size.x = int(health_percent * healthbar_max_width)

            if health_percent > 0.5:
                healthbar[i].color = HEALTHBAR_COLOR_GREEN
            elif health_percent > 0.2:
                healthbar[i].color = HEALTHBAR_COLOR_YELLOW
            else:
                healthbar[i].color = HEALTHBAR_COLOR_RED
        # if experience cluster visible
        else:
            expbar[i].size.x = int(expbar_max_width * (party.familiars[i].get_experience_toward_next_level() / float(party.familiars[i].get_experience_for_next_level())))
            level_label[i].text = "L" + str(party.familiars[i].level)

func update_health():
    is_interpolating = true

    for i in range(0, 3):
        if i < party.familiars.size():
            health_cluster[i].visible = true
            exp_cluster[i].visible = false

    var health_tween = get_tree().create_tween()
    interpolate_value = 0.0
    health_tween.tween_property(self, "interpolate_value", 1.0, 1.0)
    await health_tween.finished

    var delay_tween = get_tree().create_tween()
    delay_tween.tween_interval(0.5)
    await delay_tween.finished

    refresh()

    is_interpolating = false
    emit_signal("interpolate_finished")

func update_cursor():
    cursor.global_position = minis[cursor_index.y].global_position + Vector2(-19, 2)
    start_animation()
    dialog.set_text("Choose a\nfamiliar.")

func navigate_cursor(direction: int):
    var old_cursor_index = cursor_index.y
    cursor_index.y += direction
    if cursor_index.y < 0:
        cursor_index.y = party.familiars.size() - 1
    elif cursor_index.y >= party.familiars.size():
        cursor_index.y = 0
    if cursor_index.y != old_cursor_index:
        update_cursor()

func _process(_delta):
    if is_interpolating or exp_cluster[0].visible:
        refresh()
    if just_opened:
        just_opened = false
        return
    if party == null or is_finished or not is_open() or exp_cluster[0].visible:
        return

    if action_menu.is_open():
        if not action_menu.finished:
            return
        action_menu.finished = false
        if action_menu.choice == "":
            action_menu.close()
        elif action_menu.choice == "SWITCH":
            is_finished = true
            choice = cursor_index.y
        elif action_menu.choice == "STATUS":
            summary.open(cursor_index.y)
            await summary.finished
            summary.close()
        return
    if action_status_only_menu.is_open():
        if not action_status_only_menu.finished:
            return
        action_status_only_menu.finished = false
        if action_status_only_menu.choice == "":
            action_status_only_menu.close()
        elif action_status_only_menu.choice == "STATUS":
            summary.open(cursor_index.y)
            await summary.finished
            summary.close()
        return

    if Input.is_action_just_pressed("up"):
        navigate_cursor(-1)
    if Input.is_action_just_pressed("down"):
        navigate_cursor(1)
    if allow_back and Input.is_action_just_pressed("back"):
        is_finished = true
        choice = -1 
        emit_signal("finished")
    if Input.is_action_just_pressed("action"):
        if mode == Mode.ITEM:
            if not party.familiars[cursor_index.y].is_living():
                dialog.set_text_fancy(party.familiars[cursor_index.y].get_display_name() + " is\nout of energy!")
            else:
                is_finished = true
                choice = cursor_index.y
        elif mode == Mode.ITEM_REVIVE:
            if party.familiars[cursor_index.y].is_living():
                dialog.set_text_fancy(party.familiars[cursor_index.y].get_display_name() + " is\nalready alive!")
            else:
                is_finished = true
                choice = cursor_index.y
        elif (mode == Mode.SWITCH or mode == Mode.SWITCH_REQUIRED) and cursor_index.y != 0 and party.familiars[cursor_index.y].is_living():
            action_menu.open()
        else:
            action_status_only_menu.open()
