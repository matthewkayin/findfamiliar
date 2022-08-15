extends NinePatchRect

signal finished

onready var label = $label
onready var timer = $timer

const LINE_LENGTH = 19
const DEFAULT_CHAR_SPEED = 0.05

var speed = DEFAULT_CHAR_SPEED
var hide_on_close = true
var clear_on_finish = true

func _ready():
    timer.connect("timeout", self, "_on_char_timeout")
    visible = false

func is_open():
    return visible

func is_finished():
    return label.percent_visible == 1

func _on_char_timeout():
    label.visible_characters += 1
    if is_finished():
        timer.stop()

func open_empty():
    label.text = ""
    visible = true

func open_and_split(with_text: String):
    var as_split = split_line(with_text)
    open(as_split)

func open(with_text: String):
    label.text = with_text
    label.visible_characters = 0
    visible = true
    timer.start(speed)

func close():
    if hide_on_close:
        visible = false
    elif clear_on_finish:
        label.text = ""

func progress():
    if not is_open():
        return 
    if not is_finished():
        label.percent_visible = 1
        timer.stop()
    else:
        close()
        emit_signal("finished")
    
func _process(_delta):
    if Input.is_action_just_pressed("action"):
        progress()

func split_line(line: String):
    return split_lines([line])[0]

func split_lines(lines):
    var result_lines = []
    for line in lines:
        var words = line.split(" ")
        var next_line = ["", ""]
        var next_line_row = 0
        while words.size() != 0:
            var next_word = words[0]
            words.remove(0)

            var space_required = next_word.length()
            if next_line[next_line_row] != "":
                space_required += 1
            if next_line[next_line_row].length() + space_required > LINE_LENGTH:
                if next_line_row == 1:
                    result_lines.append(next_line[0] + "\n" + next_line[1])
                    next_line = ["", ""]
                    next_line_row = 0
                else:
                    next_line_row = 1

            if next_line[next_line_row] != "":
                next_word = " " + next_word
            next_line[next_line_row] += next_word
        if next_line[0] != "":
            result_lines.append(next_line[0] + "\n" + next_line[1])

    return result_lines
