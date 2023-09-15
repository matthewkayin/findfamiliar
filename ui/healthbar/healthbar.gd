extends Control
class_name Healthbar

signal finished

@onready var name_label = $name_label
@onready var level_label = $level_label
@onready var health = $health
@onready var health_amount = $health/health_amount
@onready var healthbar = $health/healthbar
@onready var conditions = $conditions

@export var is_enemy = false

const HEALTHBAR_COLOR_GREEN = Color8(0, 184, 0, 255)
const HEALTHBAR_COLOR_YELLOW = Color8(248, 168, 0, 255)
const HEALTHBAR_COLOR_RED = Color8(248, 0, 0, 255)

var party: Party

var healthbar_max_width: int
var displayed_health: float
var is_interpolating: bool = false

func _ready():
    healthbar_max_width = healthbar.size.x
    party = get_node("/root/enemy_party") if is_enemy else get_node("/root/player_party")
    visible = false

func open():
    displayed_health = party.get_familiar(0).health
    refresh()
    visible = true

func close():
    visible = false

func refresh():
    # refresh healthbar
    var familiar = party.get_familiar(0)
    name_label.text = familiar.get_display_name()
    level_label.text = "Lv" + str(familiar.level)
    health_amount.text = str(int(displayed_health)) + "/" + str(familiar.max_health)
    var health_percent: float = displayed_health / float(familiar.max_health)
    healthbar.size.x = int(health_percent * healthbar_max_width)

    if health_percent > 0.5:
        healthbar.color = HEALTHBAR_COLOR_GREEN
    elif health_percent > 0.2:
        healthbar.color = HEALTHBAR_COLOR_YELLOW
    else:
        healthbar.color = HEALTHBAR_COLOR_RED

    # refresh conditions
    for child in conditions.get_children():
        child.visible = false
        child.get_child(1).visible = false
    var condition_index = 0
    if familiar.condition != Condition.Type.NONE:
        conditions.get_child(condition_index).visible = true
        conditions.get_child(condition_index).get_child(0).frame = Condition.INFO[familiar.condition].icon_frame
        condition_index += 1
    for stat_index in range(0, Familiar.STAT_NAMES.size()):
        var stage = familiar[Familiar.STAT_NAMES[stat_index] + "_stage"]
        if stage == 0:
            continue
        var offset = stage - 1 if stage > 0 else 5 + abs(stage)
        conditions.get_child(condition_index).visible = true
        conditions.get_child(condition_index).get_child(0).frame = stat_index
        conditions.get_child(condition_index).get_child(1).frame = offset
        conditions.get_child(condition_index).get_child(1).visible = true
        condition_index += 1
    
func fast_update():
    displayed_health = party.get_familiar(0).health
    refresh()

func update():
    is_interpolating = true
    var health_tween = get_tree().create_tween()
    health_tween.tween_property(self, "displayed_health", party.get_familiar(0).health, 1.0)
    await health_tween.finished
    is_interpolating = false
    refresh()
    emit_signal("finished")

func _process(_delta):
    if party == null:
        return
    if is_interpolating:
        refresh()
