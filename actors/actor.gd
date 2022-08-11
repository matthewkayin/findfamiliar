extends Area2D

onready var sprite = $sprite
onready var map = get_parent().get_node("tilemap")

const TILE_SIZE = Vector2(32, 32)

var input_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var target_position: Vector2 = Vector2.ZERO

func _ready():
    map.reserve_tile(position)

func is_moving():
    return target_position != Vector2.ZERO

func handle_input():
    for direction in range(0, Direction.NAMES.size()):
        if Input.is_action_just_pressed(Direction.NAMES[direction]):
            input_direction = Direction.VECTORS[direction]
        if Input.is_action_just_released(Direction.NAMES[direction]):
            input_direction = Vector2.ZERO
            for other_direction in range(0, Direction.NAMES.size()):
                if other_direction == direction:
                    continue
                if Input.is_action_pressed(Direction.NAMES[other_direction]):
                    input_direction = Direction.VECTORS[other_direction]
                    break

func _process(_delta):
    handle_input()
    move()
    update_sprite()

func move():
    if is_moving():
        facing_direction = position.direction_to(target_position)
        if position.distance_to(target_position) <= 1:
            position = target_position
        else:
            position += facing_direction  * 1
        if position == target_position:
            var old_position = position - (facing_direction * TILE_SIZE)
            map.free_tile(old_position)
            target_position = Vector2.ZERO
    if not is_moving() and input_direction != Vector2.ZERO:
        var desired_target = position + (input_direction * TILE_SIZE)
        if map.is_tile_free(desired_target):
            target_position = desired_target
            map.reserve_tile(target_position)


func update_sprite():
    if facing_direction == Vector2.UP:
        sprite.play("back")
    elif facing_direction == Vector2.DOWN:
        sprite.play("front")
    else: 
        sprite.play("side")
    
    sprite.flip_h = facing_direction == Vector2.LEFT
    if not is_moving():
        sprite.stop()
        sprite.frame = 0