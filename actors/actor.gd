extends Area2D

signal took_step

onready var map = get_parent().get_node("tilemap")
onready var pause_menu = get_parent().get_node("ui/pause_menu")
onready var sprite = $sprite
onready var move_input_timer = $move_input_timer

const TILE_SIZE = Vector2(32, 32)

var input_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var target_position = null
var paused: bool = false
var speed: int = 2.0

func _ready():
    add_to_group("actors")
    map.reserve_tile(position)

func is_moving():
    return target_position != null

func handle_input():
    var previous_input_direction = input_direction
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

    if input_direction != Vector2.ZERO:
        facing_direction = input_direction
    if previous_input_direction == Vector2.ZERO and previous_input_direction != input_direction:
        move_input_timer.start(0.1)
    if input_direction == Vector2.ZERO and not move_input_timer.is_stopped():
        move_input_timer.stop()
    
    if Input.is_action_just_pressed("menu"):
        if not paused:
            for actor in get_tree().get_nodes_in_group("actors"):
                actor.pause()
            pause_menu.open()
        else:
            for actor in get_tree().get_nodes_in_group("actors"):
                actor.resume()
            pause_menu.close()

func _process(_delta):
    if paused and pause_menu.choice == ChoiceDialog.NONE:
        for actor in get_tree().get_nodes_in_group("actors"):
            actor.resume()
    handle_input()
    move()
    update_sprite()

func move():
    if paused:
        return
    if is_moving():
        facing_direction = position.direction_to(target_position)
        if position.distance_to(target_position) <= speed:
            position = target_position
        else:
            position += facing_direction * speed
        if position == target_position:
            var old_position = position - (facing_direction * TILE_SIZE)
            map.free_tile(old_position)
            target_position = null
    if not is_moving() and move_input_timer.is_stopped() and input_direction != Vector2.ZERO:
        var desired_target = position + (input_direction * TILE_SIZE)
        if map.is_tile_free(desired_target):
            target_position = desired_target
            map.reserve_tile(target_position)

func update_sprite():
    if paused:
        return
    var was_stopped = not sprite.is_playing()
    if facing_direction == Vector2.UP:
        sprite.play("back")
    elif facing_direction == Vector2.DOWN:
        sprite.play("front")
    else: 
        sprite.play("side")
    if was_stopped:
        sprite.frame = 1

    sprite.flip_h = facing_direction == Vector2.LEFT
    if input_direction == Vector2.ZERO:
        sprite.stop()
        sprite.frame = 0

    sprite.speed_scale = 1.0
    if sprite.is_playing() and not is_moving():
        sprite.speed_scale = 0.5

func pause():
    sprite.stop()
    paused = true

func resume():
    sprite.play()
    paused = false
