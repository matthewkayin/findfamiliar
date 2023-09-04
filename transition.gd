extends CanvasLayer

signal finished

@onready var color_rect = $color_rect

var progress: float = 0.0
var is_finished = true

func clear():
    progress = 0.0
    color_rect.material.set_shader_parameter("progress", progress)

func play_transition():
    progress = 0.0
    is_finished = false

func _process(delta):
    if is_finished:
        return
    progress = min(progress + delta, 1.5)
    color_rect.material.set_shader_parameter("progress", max(progress - 0.5, 0))
    if progress == 1.5:
        is_finished = true
        emit_signal("finished")
