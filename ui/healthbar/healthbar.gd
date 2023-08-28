extends Control

signal finished

enum StatModFrame {
    STR_UP = 1,
    STR_UP2 = 2,
    STR_DOWN = 3,
    STR_DOWN2 = 4,
    INT_UP = 6,
    INT_UP2 = 7,
    INT_DOWN = 8,
    INT_DOWN2 = 9,
    DEF_UP = 11,
    DEF_UP2 = 12,
    DEF_DOWN = 13,
    DEF_DOWN2 = 14,
    AGI_UP = 16,
    AGI_UP2 = 17,
    AGI_DOWN = 18,
    AGI_DOWN2 = 19
}

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
    if is_enemy:
        conditions.position.x = 96
    party = get_node("/root/enemy_party") if is_enemy else get_node("/root/player_party")
    visible = false

func open():
    displayed_health = party.familiars[0].health
    refresh()
    visible = true

func close():
    visible = false

func refresh():
    # refresh healthbar
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

    # refresh conditions
    var condition_icon_frames = []
    if familiar.condition != Condition.Type.NONE:
        condition_icon_frames.append(familiar.condition)
    var base_frame = [StatModFrame.STR_UP, StatModFrame.INT_UP, StatModFrame.DEF_UP, StatModFrame.AGI_UP]
    for i in range(0, Familiar.STAT_NAMES.size()):
        var stage = familiar[Familiar.STAT_NAMES[i] + "_stage"]
        if stage != 0:
            var offset = stage - 1 if stage > 0 else 1 + abs(stage)
            condition_icon_frames.append(base_frame[i] + offset)
    for i in range(0, conditions.get_child_count()):
        if i >= condition_icon_frames.size():
            conditions.get_child(i).visible = false
            continue
        conditions.get_child(i).visible = true
        conditions.get_child(i).get_child(0).frame = condition_icon_frames[i]

func fast_update():
    displayed_health = party.familiars[0].health
    refresh()

func update():
    is_interpolating = true
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
