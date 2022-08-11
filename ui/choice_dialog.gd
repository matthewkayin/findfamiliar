extends NinePatchRect
class_name ChoiceDialog

signal finished

const NONE = "NONE"
const CHOOSING = "CHOOSING"

onready var cursor = $cursor

export var allow_back = true

var choices = []
var choices_size = Vector2.ZERO
var cursor_index = Vector2.ZERO
var choice = NONE

func _ready():
    for column in $choices.get_children():
        var new_column = []
        for row in column.get_children():
            new_column.append(row)
        choices.append(new_column)
    choices_size = Vector2(choices.size(), choices[0].size())

func refresh_cursor():
    cursor.position = choices[cursor_index.x][cursor_index.y].rect_position - Vector2(16, 0)

func set_cursor_index(to_position: Vector2):
    cursor_index = to_position
    refresh_cursor()

func move_cursor(direction: Vector2):
    cursor_index += direction
    if cursor_index.y < 0:
        cursor_index.y = choices_size.y - 1
    elif cursor_index.y >= choices_size.y:
        cursor_index.y = 0
    if cursor_index.x < 0:
        cursor_index.x = choices_size.x - 1
    elif cursor_index.x >= choices_size.x:
        cursor_index.x = 0
    refresh_cursor()

func set_choice_labels(values):
    for x in range(0, choices.size()):
        for y in range(0, choices[x].size()):
            choices[x][y].text = ""
    for x in range(0, values.size()):
        for y in range(0, values[x].size()):
            choices[x][y].text = values[x][y]
    choices_size = Vector2(values.size(), values[0].size())

func open():
    choice = CHOOSING
    visible = true
    set_cursor_index(Vector2.ZERO)

func close():
    visible = false
    emit_signal("finished")

func _process(_delta):
    if choice != CHOOSING:
        return

    if Input.is_action_just_pressed("back") and allow_back:
        choice = "NONE"
        close()
        return

    if Input.is_action_just_pressed("action"):
        choice = choices[cursor_index.x][cursor_index.y].text
        close()
        return

    for i in range(0, Direction.NAMES.size()):
        if Input.is_action_just_pressed(Direction.NAMES[i]):
            move_cursor(Direction.VECTORS[i])
            return
