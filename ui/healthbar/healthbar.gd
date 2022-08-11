extends Control

signal finished

onready var tween = $tween
onready var healthbar = $healthbar
onready var manabar = $manabar
onready var health_label = $healthbar/value
onready var mana_label = $manabar/value
onready var name_label = $name
onready var level = $level

var familiar = null

var displayed_health = 0
var displayed_max_health = 0
var displayed_mana = 0
var displayed_max_mana = 0

func _ready():
    tween.connect("tween_all_completed", self, "_on_tween_finished")

func _on_tween_finished():
    emit_signal("finished")

func set_familiar(to_familiar: Familiar):
    familiar = to_familiar
    displayed_health = familiar.health
    displayed_max_health = familiar.max_health
    displayed_mana = familiar.mana
    displayed_max_mana = familiar.max_mana
    name_label.text = familiar.get_name()
    level.text = "L" + String(familiar.level)
    refresh()

func refresh():
    var health_percent = 0
    if displayed_max_health != 0:
        health_percent = displayed_health / displayed_max_health
    healthbar.region_rect.size.x = int(health_percent * healthbar.texture.get_width())
    health_label.text = String(displayed_health) + " / " + String(displayed_max_health)

    var mana_percent = 0
    if displayed_max_mana != 0:
        mana_percent = displayed_mana / displayed_max_mana
    manabar.region_rect.size.x = int(mana_percent * manabar.texture.get_width())
    mana_label.text = String(displayed_mana) + " / " + String(displayed_max_mana)

func update():
    if displayed_health != familiar.health:
        tween.interpolate_property(self, "displayed_health", displayed_health, familiar.health, 1.0)
    if displayed_mana != familiar.mana:
        tween.interpolate_property(self, "displayed_mana", displayed_mana, familiar.mana, 1.0)