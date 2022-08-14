extends Sprite

signal finished

onready var tween = $tween
onready var timer = $timer

onready var anim_point_1 = position
onready var anim_point_2 = Vector2(264, 100)

const ANIM_TIME = 1.0

var anim_timer = 0.0
var shakes = 0
var success = true

func _ready():
    visible = false

func animate(item: Item, num_shakes: int, is_success: bool):
    texture = load("res://ui/gem_sprite/gems/" + item.name.to_lower() + ".png")
    shakes = num_shakes
    success = is_success
    position = anim_point_1
    visible = true

    anim_timer = ANIM_TIME

func animate_finish():
    tween.interpolate_property(self, "position", position, position + Vector2(0, -5), 0.2)
    tween.start()
    yield(tween, "tween_all_completed")
    tween.interpolate_property(self, "position", position, position + Vector2(0, 5), 0.2)
    tween.start()
    yield(tween, "tween_all_completed")

    timer.start(0.3)
    yield(timer, "timeout")
    for shake_index in range(0, shakes):

        var shake_direction = -1
        if shake_index % 2 == 0:
            shake_direction = 1

        tween.interpolate_property(self, "rotation_degrees", rotation_degrees, 30 * shake_direction, 0.3)
        tween.start()
        yield(tween, "tween_all_completed")
        tween.interpolate_property(self, "rotation_degrees", rotation_degrees, 10 * shake_direction * -1, 0.4)
        tween.start()
        yield(tween, "tween_all_completed")
        tween.interpolate_property(self, "rotation_degrees", rotation_degrees, 0, 0.3)
        tween.start()
        yield(tween, "tween_all_completed")

        timer.start(0.3)
        yield(timer, "timeout")

    if not success:
        visible = false
        var enemy_sprite = get_parent().get_node_or_null("enemy_sprite")
        if enemy_sprite != null:
            enemy_sprite.visible = true

    emit_signal("finished")

func _process(delta):
    if anim_timer <= 0:
        return

    anim_timer -= delta
    if anim_timer <= 0:
        position = anim_point_2
        var enemy_sprite = get_parent().get_node_or_null("enemy_sprite")
        if enemy_sprite != null:
            enemy_sprite.visible = false
        animate_finish()
    else:
        var percent_complete = 1.0 - (anim_timer / ANIM_TIME)
        position.x = anim_point_1.x + ((anim_point_2.x - anim_point_1.x) * percent_complete)
        var theta = 2.64 * percent_complete
        position.y = 202 - (200 * sin(theta))
