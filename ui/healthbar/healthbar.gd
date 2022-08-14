extends Control

signal finished

onready var health_group = $health
onready var mana_group = $mana
onready var exp_group = $experience
onready var healthbar = $health/bar
onready var manabar = $mana/bar
onready var health_label = $health/value
onready var mana_label = $mana/value
onready var expbar = $experience/bar
onready var exp_label = $experience/value
onready var name_label = $name
onready var level = $level

const INTERPOLATE_DURATION = 1.0

var familiar = null

var displayed_health = 0.0
var displayed_max_health = 0.0
var displayed_mana = 0.0
var displayed_max_mana = 0.0
var displayed_exp = 0.0
var displayed_max_exp = 0.0

var interpolate_timer = 0.0
var interpolate_health_start 
var interpolate_mana_start

var exp_mode = false

func is_finished():
    return interpolate_timer <= 0.0

func _on_tween_finished():
    emit_signal("finished")

func set_familiar(to_familiar: Familiar):
    familiar = to_familiar
    displayed_health = float(familiar.health)
    displayed_max_health = float(familiar.max_health)
    displayed_mana = float(familiar.mana)
    displayed_max_mana = float(familiar.max_mana)
    name_label.text = familiar.get_name()
    level.text = "L" + String(familiar.level)
    refresh()

func set_exp_mode(value: bool):
    exp_mode = value
    if exp_mode:
        health_group.visible = false
        mana_group.visible = false
        exp_group.visible = true
    else:
        health_group.visible = true
        mana_group.visible = true
        exp_group.visible = false

func refresh():
    if exp_mode:
        var exp_percent = 0
        if displayed_max_exp != 0:
            exp_percent = displayed_exp / displayed_max_exp
        expbar.region_rect.size.x = int(exp_percent * expbar.texture.get_width())
        exp_label.text = String(int(displayed_exp)) + " / " + String(int(displayed_max_exp))

        return

    var health_percent = 0
    if displayed_max_health != 0:
        health_percent = displayed_health / displayed_max_health
    healthbar.region_rect.size.x = int(health_percent * healthbar.texture.get_width())
    health_label.text = String(int(displayed_health)) + " / " + String(int(displayed_max_health))

    var mana_percent = 0
    if displayed_max_mana != 0:
        mana_percent = displayed_mana / displayed_max_mana
    manabar.region_rect.size.x = int(mana_percent * manabar.texture.get_width())
    mana_label.text = String(int(displayed_mana)) + " / " + String(int(displayed_max_mana))

func update():
    if displayed_health != familiar.health or displayed_mana != familiar.mana:
        interpolate_health_start = displayed_health
        interpolate_mana_start = displayed_mana
        interpolate_timer = INTERPOLATE_DURATION

func _process(delta):
    if familiar == null:
        return
    if exp_mode:
        if displayed_exp != familiar.get_current_experience() or displayed_max_exp != familiar.get_experience_tnl():
            displayed_exp = float(familiar.get_current_experience())
            displayed_max_exp = float(familiar.get_experience_tnl())
            refresh()
    if not is_finished():
        interpolate_timer -= delta
        var interpolate_percent = 1.0 - (interpolate_timer / INTERPOLATE_DURATION)
        if is_finished():
            displayed_health = float(familiar.health)
            displayed_mana = float(familiar.mana)
            emit_signal("finished")
        else:
            displayed_health = interpolate_health_start + ((familiar.health - interpolate_health_start) * interpolate_percent)
            displayed_mana = interpolate_mana_start + ((familiar.mana - interpolate_mana_start) * interpolate_percent)
        refresh()
