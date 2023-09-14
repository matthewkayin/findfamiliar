extends Node2D

@onready var sprite = $sprite
@onready var door = $door

@export var leads_to: String

func _ready():
    add_to_group("obstacles")
    add_to_group("houses")
    door.play("closed")

func is_door_coordinate(coordinate: Vector2):
    return coordinate == position + door.position

func is_blocking_coordinate(coordinate: Vector2):
    return coordinate.x >= position.x and coordinate.x <= position.x + sprite.texture.get_width() - 16 and coordinate.y >= position.y and coordinate.y <= position.y + sprite.texture.get_height() - 16

func open_door():
    door.play("open")
    await door.animation_finished
    door.play("opened")
