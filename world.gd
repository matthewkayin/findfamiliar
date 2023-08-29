extends Node2D
class_name World

const TILE_SIZE: int = 16
const DIRECTIONS = {
    "up": Vector2.UP,
    "right": Vector2.RIGHT,
    "down": Vector2.DOWN,
    "left": Vector2.LEFT
}

@onready var tilemap = $tilemap

var tile_blocked

func _ready():
    pass

static func get_direction_name(from_direction: Vector2) -> String:
    for direction_name in DIRECTIONS.keys():
        if DIRECTIONS[direction_name] == from_direction:
            return direction_name
    return ""

func _process(_delta):
    pass
