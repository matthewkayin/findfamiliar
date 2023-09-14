extends NinePatchRect
class_name BestiaryEntry

signal finished

@onready var sprite = $sprite_frame/sprite
@onready var name_label = $name_frame/name_label
@onready var type_label = $name_frame/name_label/type_label/type_value
@onready var type_icon = $name_frame/name_label/type_label/type_icon
@onready var desc_frame = $desc_frame
@onready var desc_label = $desc_frame/label
@onready var page_label = $header/page_label
@onready var page_left_arrow = $header/page_left_arrow
@onready var page_right_arrow = $header/page_right_arrow
@onready var dialog = $dialog
@onready var actions = $actions

enum Mode {
    SINGLE_ENTRY,
    FULL
}

var mode
var species: Species
var just_open = false
var choice: String

func _ready():
    visible = false

func close():
    visible = false

func open(p_species: Species, in_mode: Mode):
    species = p_species
    mode = in_mode

    page_label.visible = mode == Mode.FULL
    page_left_arrow.visible = mode == Mode.FULL
    page_right_arrow.visible = mode == Mode.FULL

    sprite.texture = load("res://battle/sprites/front/" + species.name.to_lower().replace(" ", "-") + ".png")
    name_label.text = species.name
    type_label.text = Types.Type.keys()[species.type]
    type_icon.frame = species.type
    desc_label.text = species.desc

    visible = true
    just_open = true

func _process(_delta):
    if just_open:
        just_open = false
        return
    if actions.is_open() and actions.finished:
        choice = actions.choice
        emit_signal("finished")
    if dialog.is_open():
        return

    if Input.is_action_just_pressed("back") and mode == Mode.FULL:
        emit_signal("finished")
    if Input.is_action_just_pressed("action") and mode == Mode.SINGLE_ENTRY:
        desc_frame.visible = false
        var delay_tween = get_tree().create_tween()
        delay_tween.tween_interval(0.25)
        await delay_tween.finished
        dialog.open("Give a nickname to\nthe captured " + species.name + "?")
        await dialog.finished
        actions.open()