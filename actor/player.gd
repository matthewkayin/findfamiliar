extends Node2D

@onready var sprite = $sprite

const SPEED: int = 48

var input_direction: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var next_tile_position: Vector2

func _ready():
    pass

func _process(delta):
    input_direction = Vector2.ZERO
    for direction_name in World.DIRECTIONS.keys():
        if Input.is_action_pressed(direction_name):
            input_direction = World.DIRECTIONS[direction_name]
            break

    if not is_moving and input_direction != Vector2.ZERO:
        next_tile_position = position + (input_direction * World.TILE_SIZE)
        is_moving = true
    if is_moving:
        direction = position.direction_to(next_tile_position)
        var step = SPEED * delta
        if position.distance_to(next_tile_position) <= step:
            if input_direction == direction:
                position += direction * step
            else:
                position = next_tile_position
            if input_direction == Vector2.ZERO:
                is_moving = false
            else:
                next_tile_position += (input_direction * World.TILE_SIZE)
        else:
            position += direction * step

    var direction_name = World.get_direction_name(direction)
    if direction_name == "left" or direction_name == "right":
        direction_name = "side"
    var anim_prefix = "walk" if is_moving else "idle"
    sprite.play(anim_prefix + "_" + direction_name)
    sprite.flip_h = direction == Vector2.RIGHT
