extends NinePatchRect
class_name ChoiceDialog

signal finished

const NONE = "NONE"
const CHOOSING = "CHOOSING"

onready var cursor = $cursor

export var allow_back = true
export var close_on_choice = true

var choices = []
var choices_size = []
var cursor_index = Vector2.ZERO
var choice = NONE
var just_opened = false

func _ready():
    for column in $choices.get_children():
        var new_column = []
        for row in column.get_children():
            new_column.append(row)
        choices.append(new_column)
        choices_size.append(new_column.size())

func refresh_cursor():
    cursor.position = choices[cursor_index.x][cursor_index.y].rect_position - Vector2(16, 0)

func set_cursor_index(to_position: Vector2):
    cursor_index = to_position
    refresh_cursor()

func move_cursor(direction: Vector2):
    cursor_index += direction
    if cursor_index.y < 0:
        cursor_index.y = choices_size[cursor_index.x] - 1
    elif cursor_index.y >= choices_size[cursor_index.x]:
        cursor_index.y = 0
    if cursor_index.x < 0:
        cursor_index.x = choices_size.size() - 1
    elif cursor_index.x >= choices_size.size():
        cursor_index.x = 0
    refresh_cursor()

func set_choice_labels(values):
    choices_size = []
    for x in range(0, choices.size()):
        for y in range(0, choices[x].size()):
            choices[x][y].text = ""
    for x in range(0, values.size()):
        choices_size.append(values[x].size())
        for y in range(0, values[x].size()):
            choices[x][y].text = values[x][y]

func open():
    choice = CHOOSING
    visible = true
    just_opened = true
    set_cursor_index(Vector2.ZERO)

func close():
    visible = false
    emit_signal("finished")

func choose():
    choice = choices[cursor_index.x][cursor_index.y].text
    if close_on_choice:
        close()

func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if choice != CHOOSING:
        return

    if Input.is_action_just_pressed("back") and allow_back:
        choice = "NONE"
        close()
        return

    if Input.is_action_just_pressed("action"):
        choose()
        return

    for i in range(0, Direction.NAMES.size()):
        if Input.is_action_just_pressed(Direction.NAMES[i]):
            move_cursor(Direction.VECTORS[i])
            return
