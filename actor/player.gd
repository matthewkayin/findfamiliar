extends Node2D

@onready var director = get_node("/root/director")
@onready var pause_menu = get_node("../ui/pause_menu")

@onready var sprite = $sprite
@onready var move_input_timer = $move_input_timer
@onready var tallgrass_step = $tallgrass_step

const SPEED: int = 48
const MOVE_INPUT_DELAY: float = 0.1

var input_direction: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var next_tile_position: Vector2

func _process(delta):
    # check input
    if Input.is_action_just_pressed("menu"):
        pause_menu.open()
    input_direction = Vector2.ZERO
    for direction_name in World.DIRECTIONS.keys():
        if Input.is_action_pressed(direction_name):
            input_direction = World.DIRECTIONS[direction_name]
            break

    # if user released move key before we started moving, then cancel movement
    if input_direction == Vector2.ZERO and not move_input_timer.is_stopped():
        is_moving = false
        move_input_timer.stop()
    if input_direction != Vector2.ZERO and not is_moving and move_input_timer.is_stopped() and direction != input_direction:
        move_input_timer.start(MOVE_INPUT_DELAY)

    # get movement next tile
    if not is_moving and input_direction != Vector2.ZERO and move_input_timer.is_stopped():
        var next_position = position + (input_direction * World.TILE_SIZE)
        if not get_parent().is_tile_blocked(next_position / World.TILE_SIZE):
            next_tile_position = next_position
            is_moving = true

    # set facing direction
    if is_moving:
        direction = position.direction_to(next_tile_position)
    elif input_direction != Vector2.ZERO:
        direction = input_direction

    # handle movement
    if is_moving: 
        # tall grass animation
        if get_parent().is_tall_grass(next_tile_position / World.TILE_SIZE):
            tallgrass_step.play("step")
        else:
            tallgrass_step.play("default")

        var step = SPEED * delta
        # player has reached tile
        if position.distance_to(next_tile_position) <= step:
            var entering_battle = get_parent().check_for_encounter(next_tile_position / World.TILE_SIZE)

            var next_position = next_tile_position + (input_direction * World.TILE_SIZE)
            var next_position_blocked = get_parent().is_tile_blocked(next_position / World.TILE_SIZE)

            if input_direction == direction and not next_position_blocked and not entering_battle:
                position += direction * step
            else:
                position = next_tile_position

            if input_direction == Vector2.ZERO or next_position_blocked or entering_battle:
                is_moving = false
                if tallgrass_step.animation == "step":
                    tallgrass_step.play("in_grass")
            else:
                next_tile_position = next_position

            if entering_battle:
                input_direction = Vector2.ZERO
                is_moving = false
                director.start_battle()
        # player has not reached tile, move normally
        else:
            position += direction * step

    # sprite animation
    var direction_name = World.get_direction_name(direction)
    if direction_name == "left" or direction_name == "right":
        direction_name = "side"
    var anim_prefix = "walk" if (is_moving or input_direction != Vector2.ZERO) else "idle"
    sprite.speed_scale = 0.5 if anim_prefix == "walk" and not is_moving else 1.0
    sprite.play(anim_prefix + "_" + direction_name)
    sprite.flip_h = direction == Vector2.RIGHT
