extends NinePatchRect

signal updated_cursor

@export var allow_back: bool = false

@onready var cursor = $cursor
@onready var choice_labels = $options/col1.get_children()
@onready var up_arrow = $up_arrow
@onready var down_arrow = $down_arrow
@onready var item_info = $item_info

var items: Dictionary
var cursor_index: int = 0
var scroll_offset: int = 0
var choice: Item = null
var finished: bool = false
var just_opened: bool = false

func _ready():
    finished = false
    visible = false

func is_open():
    return visible 

func open(with_items: Dictionary, remember_cursor: bool = false):
    items = with_items
    if not remember_cursor:
        cursor_index = 0
        scroll_offset = 0
    refresh()
    finished = false
    visible = true
    just_opened = true

func close():
    visible = false

func refresh():
    up_arrow.visible = scroll_offset > 0
    down_arrow.visible = scroll_offset + choice_labels.size() < items.keys().size()
    for i in range(0, choice_labels.size()):
        if scroll_offset + i >= items.size():
            choice_labels[i].visible = false
            continue
        choice_labels[i].visible = true
        choice_labels[i].text = items.keys()[scroll_offset + i].name
        choice_labels[i].get_child(0).text = "x" + str(items[items.keys()[scroll_offset + i]])
    update_cursor()
    item_info.open(items.keys()[scroll_offset + cursor_index])

func update_cursor():
    cursor.position = choice_labels[cursor_index].position + Vector2(-10, 6)
    emit_signal("updated_cursor")

func navigate_cursor(direction: int):
    cursor_index += direction
    if cursor_index < 0:
        cursor_index = 0
        if scroll_offset > 0:
            scroll_offset -= 1
    elif scroll_offset == 0 and cursor_index >= items.keys().size():
        cursor_index = items.keys().size() - 1
    elif cursor_index >= choice_labels.size():
        cursor_index = choice_labels.size() - 1
        if scroll_offset + choice_labels.size() < items.keys().size():
            scroll_offset += 1
    refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if just_opened:
        just_opened = false
        return
    if finished or not is_open():
        return

    if Input.is_action_just_pressed("up"):
        navigate_cursor(-1)
    if Input.is_action_just_pressed("down"):
        navigate_cursor(1)
    if allow_back and Input.is_action_just_pressed("back"):
        finished = true
        choice = null
    if Input.is_action_just_pressed("action"):
        finished = true
        choice = items.keys()[scroll_offset + cursor_index]
