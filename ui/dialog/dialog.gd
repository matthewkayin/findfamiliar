extends NinePatchRect

signal finished

@onready var timer = $timer
@onready var label = $label

const CHAR_SPEED: float = 0.05

var is_finished: bool = false

func _ready():
    timer.timeout.connect(_on_timer_timeout)
    visible = false

func is_open():
    return visible

func open(with_text: String):
    label.text = with_text
    label.visible_ratio = 0.0
    visible = true
    is_finished = false
    timer.start(CHAR_SPEED)

func clear():
    label.text = ""

func _on_timer_timeout():
    label.visible_characters += 1
    if label.visible_ratio == 1.0:
        timer.stop()

func _process(_delta):
    if is_finished or not is_open():
        return

    if Input.is_action_just_pressed("action") and label.visible_ratio != 1.0:
        label.visible_ratio = 1.0
        timer.stop()
    elif Input.is_action_just_pressed("action"):
        is_finished = true
        emit_signal("finished")