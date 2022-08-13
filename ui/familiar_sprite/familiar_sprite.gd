extends Sprite

signal finished

onready var tween = $tween
onready var timer = $timer

export var flipped = false

var x_direction = 1

func _ready():
    if flipped:
        x_direction = -1

func is_finished():
    return not tween.is_active()

func set_familiar(familiar: Familiar):
    # These two lines reset the texture after the sprite has played the fainted animation
    offset = Vector2.ZERO
    region_rect.size = Vector2(56, 56)

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

func animate_death():
    tween.interpolate_property(self, "offset", offset, Vector2(0, 28), 0.5)
    tween.interpolate_property(self, "region_rect", region_rect, Rect2(region_rect.position, Vector2(56, 0)), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")

    emit_signal("finished")
