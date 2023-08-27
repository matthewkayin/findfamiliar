extends NinePatchRect

signal updated_cursor
signal closed

@export var allow_back: bool = false

@onready var cursor = $cursor

var choice_labels = []
var cursor_index = Vector2i(0, 0)
var choice: String = ""
var finished: bool = false
var just_opened: bool = false

func _ready():
    refresh_options()
    finished = false
    visible = false

func is_open():
    return visible 

func refresh_options():
    choice_labels = []
    for col in $options.get_children():
        var col_array = []
        for label in col.get_children():
            if label.text == "":
                break
            col_array.append(label)
        choice_labels.append(col_array)

func open(remember_cursor: bool = false):
    if not remember_cursor:
        cursor_index = Vector2i(0, 0)
    update_cursor()
    finished = false
    visible = true
    just_opened = true

func open_with(p_options: Array[String]):
    var col = $options.get_child(0)
    for i in range(0, col.get_child_count()):
        if i <= p_options.size() - 1:
            col.get_child(i).text = p_options[i]
        else:
            col.get_child(i).text = ""
    # refresh_options()
    open()

func close():
    visible = false
    emit_signal("closed")

func update_cursor():
    cursor.position = choice_labels[cursor_index.x][cursor_index.y].position + Vector2(-10, 6)
    emit_signal("updated_cursor")

func navigate_cursor(direction: Vector2i):
    var gone_once = false
    while choice_labels[cursor_index.x][cursor_index.y].text == "" or not gone_once:
        gone_once = true
        cursor_index += direction
        if cursor_index.x >= choice_labels.size():
            cursor_index.x = 0
        elif cursor_index.x < 0:
            cursor_index.x = choice_labels.size() - 1
        if cursor_index.y >= choice_labels[0].size():
            cursor_index.y = 0
        elif cursor_index.y < 0:
            cursor_index.y = choice_labels[0].size() - 1
    update_cursor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if finished or not is_open():
        return

    if Input.is_action_just_pressed("up"):
        navigate_cursor(Vector2.UP)
    if Input.is_action_just_pressed("down"):
        navigate_cursor(Vector2.DOWN)
    if Input.is_action_just_pressed("right"):
        navigate_cursor(Vector2.RIGHT)
    if Input.is_action_just_pressed("left"):
        navigate_cursor(Vector2.LEFT)
    if allow_back and Input.is_action_just_pressed("back"):
        finished = true
        choice = ""
    if Input.is_action_just_pressed("action"):
        finished = true
        choice = choice_labels[cursor_index.x][cursor_index.y].text
