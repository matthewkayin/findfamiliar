extends Node2D

@onready var director = get_node("/root/director")
@onready var pause_menu = get_node("../../ui/pause_menu")
@onready var dialog = get_node("../../ui/dialog")
@onready var world = get_parent().get_parent()

@onready var sprite = $sprite
@onready var move_input_timer = $move_input_timer
@onready var tallgrass_step = $tallgrass_step

const SPEED: int = 48
const MOVE_INPUT_DELAY: float = 0.1

var input_direction: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var next_tile_position: Vector2
var is_interacting: bool = false
var is_entering_duel: bool = false

func _ready():
    add_to_group("walkers")

func _process(delta):
    update_behavior(delta)
    update_sprite()

func update_behavior(delta):
    if is_entering_duel:
        return
    if is_interacting:
        if not dialog.is_open():
            is_interacting = false
        return

    # check input
    if Input.is_action_just_pressed("menu"):
        pause_menu.open()

    # interaction
    if Input.is_action_just_pressed("action") and not is_moving and not is_interacting:
        var interact_coord = position + (direction * World.TILE_SIZE)
        for npc in get_tree().get_nodes_in_group("npcs"):
            if npc.position == interact_coord and not npc.is_moving:
                npc.direction = direction * -1
                is_interacting = true
                if npc.is_duelist and not npc.is_defeated:
                    await npc.begin_duel()
                else:
                    npc.behavior_paused = true
                    for line in npc.dialog:
                        dialog.open(line)
                        await dialog.finished
                    dialog.close()
                    npc.behavior_paused = false
            break

    # directional input
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
        if not world.is_tile_blocked(next_position):
            previous_position = position
            next_tile_position = next_position
            is_moving = true

    # set facing direction
    if is_moving:
        var new_direction = position.direction_to(next_tile_position)
        if new_direction != Vector2.ZERO:
            direction = new_direction
    elif input_direction != Vector2.ZERO:
        direction = input_direction

    # handle movement
    if is_moving: 
        # tall grass animation
        if world.is_tall_grass(next_tile_position):
            tallgrass_step.play("step")
        else:
            tallgrass_step.play("default")

        var step = SPEED * delta
        # player has reached tile
        if position.distance_to(next_tile_position) <= step:
            var entering_battle = world.check_for_encounter(next_tile_position)
            var entering_duel = false
            var duel_opponent = null
            for npc in get_tree().get_nodes_in_group("npcs"):
                if npc.eyes_meet_player(next_tile_position):
                    entering_duel = true
                    duel_opponent = npc
                break

            var next_position = next_tile_position + (input_direction * World.TILE_SIZE)
            var next_position_blocked = world.is_tile_blocked(next_position)

            if input_direction == direction and not next_position_blocked and not entering_battle and not entering_duel:
                position += direction * step
            else:
                position = next_tile_position

            if input_direction == Vector2.ZERO or next_position_blocked or entering_battle:
                is_moving = false
                if tallgrass_step.animation == "step":
                    tallgrass_step.play("in_grass")
            else:
                previous_position = next_tile_position
                next_tile_position = next_position

            if entering_duel:
                input_direction = Vector2.ZERO
                is_moving = false
                is_entering_duel = true
                await duel_opponent.begin_duel()
                is_entering_duel = false
            elif entering_battle:
                input_direction = Vector2.ZERO
                is_moving = false
                director.start_battle()
        # player has not reached tile, move normally
        else:
            position += direction * step
    # elif not moving
    else:
        for npc in get_tree().get_nodes_in_group("npcs"):
            if npc.eyes_meet_player():
                is_entering_duel = true
                await npc.begin_duel()
                is_entering_duel = false
                break

func update_sprite():
    # sprite animation
    var direction_name = World.get_direction_name(direction)
    if direction_name == "left" or direction_name == "right":
        direction_name = "side"
    var anim_prefix = "walk" if ((is_moving or input_direction != Vector2.ZERO) and not is_entering_duel) else "idle"
    sprite.speed_scale = 0.5 if anim_prefix == "walk" and not is_moving else 1.0
    sprite.play(anim_prefix + "_" + direction_name)
    sprite.flip_h = direction == Vector2.RIGHT
