extends NinePatchRect

signal finished

@onready var prompt_label = $prompt_label
@onready var prompt_icon = $prompt_label/prompt_icon
@onready var input_chars = $prompt_label/prompt_icon/input_hbox
@onready var rows = [$letters_box/row1, $letters_box/row2, $letters_box/row3, $letters_box/row4, $letters_box/row5, $letters_box/row6]
@onready var confirm_label = $letters_box/confirm_box/confirm_label
@onready var cursor = $letters_box/cursor
@onready var mini_anim_timer = $mini_anim_timer
@onready var cursor_blink_timer = $cursor_blink_timer

var input: String = ""
var cursor_index: Vector2i = Vector2i.ZERO

func _ready():
    mini_anim_timer.timeout.connect(_mini_anim_timeout)
    cursor_blink_timer.timeout.connect(_cursor_blink_timeout)

    var charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz"
    var char_index = 0
    for row in rows:
        for letter in row.get_children():
            if char_index >= charset.length():
                letter.text = " "
            else:
                letter.text = charset[char_index]
                char_index += 1
    
    visible = false

func _mini_anim_timeout():
    prompt_icon.frame = (prompt_icon.frame + 1) % 2

func _cursor_blink_timeout():
    var input_index = input.length()
    if input_index == 10:
        return
    input_chars.get_child(input_index).get_child(0).visible = not input_chars.get_child(input_index).get_child(0).visible

func open(familiar: Familiar):
    prompt_label.text = familiar.species.name + "'s NICKNAME?"
    prompt_icon.texture = load("res://battle/sprites/minis/" + familiar.species.name.to_lower().replace(" ", "-") + ".png")

    input = ""
    cursor_index = Vector2i.ZERO
    mini_anim_timer.start(0.2)
    cursor_blink_timer.start(0.5)
    refresh()
    visible = true

func close():
    mini_anim_timer.stop()
    cursor_blink_timer.stop()
    visible = false

func refresh():
    var input_index = input.length()

    for i in range(0, 10):
        if i < input.length():
            input_chars.get_child(i).text = input[i]
        else:
            input_chars.get_child(i).text = " "
        if i != input_index:
            input_chars.get_child(i).get_child(0).visible = true
        input_chars.get_child(i).get_child(0).position.y = 8 if i == input_index else 4

    if cursor_index.y == 6 or input_index == 10:
        cursor.global_position = confirm_label.global_position + Vector2(-10, 15)
    else:
        cursor.global_position = rows[cursor_index.y].get_child(cursor_index.x).global_position + Vector2(-10, 15)

func navigate_cursor(direction: Vector2i):
    cursor_index += direction
    if cursor_index.x > 8:
        cursor_index.x = 0
    if cursor_index.x < 0:
        cursor_index.x = 8
    if cursor_index.y > 6:
        cursor_index.y = 0
    if cursor_index.y < 0:
        cursor_index.y = 6
    refresh()

func _process(_delta):
    if not visible:
        return

    if Input.is_action_just_pressed("up"):
        navigate_cursor(Vector2i.UP)
    if Input.is_action_just_pressed("right"):
        navigate_cursor(Vector2i.RIGHT)
    if Input.is_action_just_pressed("down"):
        navigate_cursor(Vector2i.DOWN)
    if Input.is_action_just_pressed("left"):
        navigate_cursor(Vector2i.LEFT)
    if Input.is_action_just_pressed("back"):
        if input.length() > 0:
            input = input.erase(input.length() - 1)
            refresh()
    if Input.is_action_just_pressed("action"):
        if input.length() != 0 and (cursor_index.y == 6 or input.length() == 10):
            emit_signal("finished")
            return
        input += rows[cursor_index.y].get_child(cursor_index.x).text
        refresh()