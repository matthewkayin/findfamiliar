extends NinePatchRect

signal finished

@onready var timer = $timer
@onready var label = $label

const CHAR_SPEED: float = 0.03

var is_finished: bool = false
var can_finish: bool = false
var extra_lines: Array[String] = []

func _ready():
    timer.timeout.connect(_on_timer_timeout)
    visible = false

func is_open():
    return visible

func open(with_text: String):
    extra_lines = []
    var lines = with_text.split("\n")
    for i in range(0, lines.size()):
        if i == 0:
            label.text = lines[i]
        elif i == 1:
            label.text += "\n" + lines[i]
        else:
            extra_lines.append(lines[i])
    label.visible_ratio = 0.0
    label.position.y = 11
    visible = true
    is_finished = false
    can_finish = false
    timer.start(CHAR_SPEED)

func clear():
    label.text = ""

func _on_timer_timeout():
    label.visible_characters += 1
    if label.visible_ratio == 1.0:
        timer.stop()

func read_next_line():
    if extra_lines.size() != 0:
        # add the extra line
        label.text += "\n" + extra_lines[0]
        label.visible_characters = label.text.length() - extra_lines[0].length()
        extra_lines.remove_at(0)

        # shift the text upward
        var shift_tween = get_tree().create_tween()
        shift_tween.tween_property(label, "position", label.position + Vector2(0, -24), CHAR_SPEED)
        await shift_tween.finished

        # start reading again
        timer.start(CHAR_SPEED)
    else:
        is_finished = true
        emit_signal("finished")

func _process(_delta):
    if is_finished or not is_open():
        return

    if label.visible_ratio != 1.0 and Input.is_action_just_pressed("action") and label.visible_ratio != 1.0 and not timer.is_stopped():
        label.visible_ratio = 1.0
        timer.stop()
    elif label.visible_ratio == 1.0 and Input.is_action_just_pressed("action"):
        read_next_line()