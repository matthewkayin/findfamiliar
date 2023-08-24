extends Control

signal finished

@onready var name_label = $name_label
@onready var level_label = $level_label
@onready var health = $health
@onready var health_amount = $health/health_amount
@onready var healthbar = $health/healthbar
@onready var manabar = $manabar

@export var is_enemy = false

const HEALTHBAR_COLOR_GREEN = Color8(0, 184, 0, 255)
const HEALTHBAR_COLOR_YELLOW = Color8(248, 168, 0, 255)
const HEALTHBAR_COLOR_RED = Color8(248, 0, 0, 255)

var party: Party = null
var manabar_spheres = []

var healthbar_max_width: int
var displayed_health: float
var displayed_mana: float
var is_interpolating: bool = false

func _ready():
    healthbar_max_width = healthbar.size.x
    if is_enemy:
        manabar.position.x = 0
    for i in range(0, manabar.get_child_count()):
        manabar_spheres.append(manabar.get_child(i).get_child(0))
    visible = false

func open():
    displayed_health = party.familiars[0].health
    displayed_mana = party.mana
    refresh()
    visible = true

func close():
    visible = false

func refresh():
    var mana_remaining: float = displayed_mana
    var sphere_index: int = 0
    while mana_remaining >= 1:
        manabar_spheres[sphere_index].visible = true
        manabar_spheres[sphere_index].region_rect = Rect2(Vector2(16, 0), Vector2(8, 8))
        manabar_spheres[sphere_index].offset.y = -4
        sphere_index += 1
        mana_remaining -= 1
    if mana_remaining > 0:
        var sphere_height = 8 * mana_remaining
        manabar_spheres[sphere_index].visible = true
        manabar_spheres[sphere_index].region_rect = Rect2(Vector2(16, 8 - sphere_height), Vector2(8, sphere_height))
        manabar_spheres[sphere_index].offset.y = -4 + manabar_spheres[sphere_index].region_rect.position.y
        sphere_index += 1
    for index in range(sphere_index, 3):
        manabar_spheres[index].visible = false

    var familiar = party.familiars[0]
    name_label.text = familiar.get_display_name()
    level_label.text = "L" + str(familiar.level)
    health_amount.text = str(int(displayed_health)) + "/" + str(familiar.max_health)
    var health_percent: float = displayed_health / float(familiar.max_health)
    healthbar.size.x = int(health_percent * healthbar_max_width)

    if health_percent > 0.5:
        healthbar.color = HEALTHBAR_COLOR_GREEN
    elif health_percent > 0.2:
        healthbar.color = HEALTHBAR_COLOR_YELLOW
    else:
        healthbar.color = HEALTHBAR_COLOR_RED

func fast_update():
    displayed_health = party.familiars[0].health
    refresh()

func update():
    is_interpolating = true
    var mana_tween = get_tree().create_tween()
    mana_tween.tween_property(self, "displayed_mana", party.mana, 0.5)
    var health_tween = get_tree().create_tween()
    health_tween.tween_property(self, "displayed_health", party.familiars[0].health, 1.0)
    await health_tween.finished
    is_interpolating = false
    refresh()
    emit_signal("finished")

func _process(_delta):
    if party == null:
        return
    if is_interpolating:
        refresh()
