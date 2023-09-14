extends ColorRect

signal finished

var progress: float = 0.0
var is_finished = true

func clear():
    progress = 0.0
    material.set_shader_parameter("progress", progress)

func play_transition():
    visible = true
    progress = 0.0
    is_finished = false

func _process(delta):
    if is_finished:
        return
    progress = min(progress + delta, 1.0)
    material.set_shader_parameter("progress", max((progress - 0.5), 0) * 2.0)
    if progress == 1.0:
        is_finished = true
        emit_signal("finished")

func fade_in():
    visible = true
    material.set_shader_parameter("progress", 1.0)
    var fade_tween = get_tree().create_tween()
    fade_tween.tween_property(self, "color", Color(0, 0, 0, 0), 0.5)
    await fade_tween.finished
    material.set_shader_parameter("progress", 0.0)
    color = Color(0.0, 0.0, 0.0, 1.0)

func fade_out():
    visible = true
    color = Color(0.0, 0.0, 0.0, 0.0)
    material.set_shader_parameter("progress", 1.0)
    var fade_tween = get_tree().create_tween()
    fade_tween.tween_property(self, "color", Color(0, 0, 0, 1.0), 0.5)
    await fade_tween.finished
    material.set_shader_parameter("progress", 0.0)