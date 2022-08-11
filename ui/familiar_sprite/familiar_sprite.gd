extends Sprite

signal finished

onready var tween = $tween
onready var timer = $timer

export var flipped = false

var x_direction = 1

func _ready():
    if flipped:
        x_direction = -1

func set_familiar(familiar: Familiar):
    texture = load("res://battle/familiars/" + familiar.species.name.to_lower() + ".png")
    visible = true

func animate_attack():
    var LUNGE_DISTANCE = 10

    tween.interpolate_property(self, "position", position, position + Vector2(LUNGE_DISTANCE * x_direction, 0), 0.2)
    tween.start()
    yield(tween, "tween_all_completed")

    tween.interpolate_property(self, "position", position, position + Vector2(LUNGE_DISTANCE * x_direction * -1, 0), 0.2)
    tween.start()
    yield(tween, "tween_all_completed")

    emit_signal("finished")

func animate_hurt():
    for _i in range(0, 3):
        visible = false
        timer.start(0.1)
        yield(timer, "timeout")
        visible = true
        timer.start(0.1)
        yield(timer, "timeout")

    emit_signal("finished")