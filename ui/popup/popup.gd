extends NinePatchRect

@onready var label = $label
@onready var timer = $timer

@export var timeout: bool = true
@export var timeout_duration: float = 1.0

enum PopupXAlign {
    LEFT,
    RIGHT,
    CENTER
}

enum PopupYAlign {
    TOP,
    BOT,
    CENTER
}

@export var x_align: PopupXAlign = PopupXAlign.LEFT
@export var y_align: PopupYAlign = PopupYAlign.TOP

var origin: Vector2

func _ready():
    visible = false
    origin = position 
    if x_align == PopupXAlign.RIGHT:
        origin += Vector2(size.x, 0) 
    elif x_align == PopupXAlign.CENTER:
        origin += Vector2(size.x / 2, 0) 
    if y_align == PopupYAlign.BOT: 
        origin += Vector2(0, size.y)
    elif y_align == PopupYAlign.CENTER: 
        origin += Vector2(0, size.y / 2)

func open(text: String):
    label.text = text

    var text_lines = text.split("\n")
    var text_width = 0
    for line in text_lines:
        text_width = max(text_width, line.length())
    var text_height = text_lines.size()
    size = Vector2(12 + (8 * text_width), 12 + (8 * text_height) + (4 * (text_height - 1)))

    position = origin
    if x_align == PopupXAlign.RIGHT:
        position -= Vector2(size.x, 0) 
    elif x_align == PopupXAlign.CENTER:
        position -= Vector2(size.x / 2, 0) 
    if y_align == PopupYAlign.BOT: 
        position -= Vector2(0, size.y)
    elif y_align == PopupYAlign.CENTER: 
        position -= Vector2(0, size.y / 2)

    visible = true
    timer.start(timeout_duration)
    await timer.timeout
    if timeout:
        close()

func open_many(messages: Array[String]):
    for message in messages:
        await open(message)

func close():
    visible = false
