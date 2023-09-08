extends Sprite2D

signal has_approached_player

@onready var world = get_parent().get_parent()
@onready var wait_timer = $wait_timer
@onready var exclamation = $exclamation
var player = null
var dialogbox = null

@export_multiline var behavior: String
@export_multiline var dialog: Array[String]

@export_group("duel")
@export var is_duelist: bool = false
@export_multiline var pre_duel_dialog: Array[String]

enum BehaviorAction {
    FACE,
    WALK,
    WAIT
}

const SPEED: int = 48
const FRAME_SPEED: float = 1.0 / 8.0

const ANIM_FRAMES = {
    "idle_down": [0],
    "idle_side": [6],
    "idle_up": [3],
    "walk_down": [1, 0, 2, 0],
    "walk_side": [7, 6],
    "walk_up": [4, 3, 5, 3]
}

var direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var previous_position: Vector2
var next_tile_position: Vector2
var target_position: Vector2

var anim_name = "walk_down"
var animation_timer: float = 0.0
var animation_frame: int = 0

var behaviors = []
var behavior_index = 0
var is_behaving = false
var behavior_paused = false

var is_defeated: bool = false
var is_approaching_player: bool = false

func _ready():
    add_to_group("walkers")
    add_to_group("npc")

    var behavior_lines = behavior.split("\n")
    for line in behavior_lines:
        var parts = line.split(" ")
        if parts[0] == "face":
            behaviors.append({
                "action": BehaviorAction.FACE,
                "direction": World.DIRECTIONS[parts[1]]
            })
        elif parts[0] == "walk":
            behaviors.append({
                "action": BehaviorAction.WALK,
                "direction": World.DIRECTIONS[parts[1]],
                "steps": int(parts[2])
            })
        elif parts[0] == "wait":
            behaviors.append({
                "action": BehaviorAction.WAIT,
                "duration": float(parts[1])
            })

func _process(delta):
    if player == null or dialogbox == null:
        player = get_node_or_null("../player")
        dialogbox = get_node_or_null("../../ui/dialog")
        if player == null or dialogbox == null:
            return

    # check for duel with player
    if is_duelist and not is_defeated and player.position.x % World.TILE_SIZE == 0 and player.position.y % World.TILE_SIZE == 0 and direction == position.direction_to(player.direction):
        var can_see_player = true
        var position_check_tile = Vector2(int(player.position.x / World.TILE_SIZE), int(player.position.y / World.TILE_SIZE)) + (direction * World.TILE_SIZE)
        while position_check_tile != player.position:
            if world.is_tile_blocked(position_check_tile):
                can_see_player = false
                break
            position_check_tile += direction * World.TILE_SIZE
        if can_see_player:
            begin_duel()

    if not is_behaving and not behavior_paused:
        if behaviors[behavior_index].action == BehaviorAction.FACE:
            direction = behaviors[behavior_index].direction
            behavior_index = (behavior_index + 1) % behaviors.size()
        elif behaviors[behavior_index].action == BehaviorAction.WAIT:
            wait_timer.start(behaviors[behavior_index].duration)
            is_behaving = true
        elif behaviors[behavior_index].action == BehaviorAction.WALK:
            target_position = position + (behaviors[behavior_index].steps * behaviors[behavior_index].direction * World.TILE_SIZE)
            is_behaving = true

    if is_behaving and behaviors[behavior_index].action == BehaviorAction.WAIT and wait_timer.is_stopped() and not behavior_paused:
        is_behaving = false
        behavior_index = (behavior_index + 1) % behaviors.size()
    elif is_behaving and behaviors[behavior_index].action == BehaviorAction.WALK and not is_moving and not behavior_paused:
        var next_position = position + (behaviors[behavior_index].direction * World.TILE_SIZE)
        if not world.is_tile_blocked(next_position):
            previous_position = position
            next_tile_position = next_position
            is_moving = true

    if is_moving and not behavior_paused:
        # set facing direction
        var new_direction = position.direction_to(next_tile_position)
        if new_direction != Vector2.ZERO:
            direction = new_direction
        
        var step = SPEED * delta
        # if has reached tile
        if position.distance_to(next_tile_position) <= step:
            var input_direction = Vector2.ZERO if next_tile_position == target_position else behaviors[behavior_index].direction
            var next_position = next_tile_position + (input_direction * World.TILE_SIZE)
            var next_position_blocked = world.is_tile_blocked(next_position)

            if input_direction == direction and not next_position_blocked:
                position += direction * step
            else:
                position = next_tile_position

            if input_direction == Vector2.ZERO or next_position_blocked:
                is_moving = false
            else:
                previous_position = next_tile_position
                next_tile_position = next_position
            
            if input_direction == Vector2.ZERO:
                is_behaving = false
                behavior_index = (behavior_index + 1) % behaviors.size()
        else:
            position += direction * step
    elif is_moving and is_approaching_player:
        var step = SPEED * delta
        if position.distance_to(target_position) <= step:
            position = target_position
            is_moving = false
            is_approaching_player = false
            emit_signal("has_approached_player")
        else:
            position += direction * step
    # end is moving

    # determine animation name
    var direction_name = World.get_direction_name(direction)
    if direction_name == "left" or direction_name == "right":
        direction_name = "side"
    var anim_prefix = "walk" if is_moving else "idle"
    var previous_anim_name = anim_name
    anim_name = anim_prefix + "_" + direction_name
    # if animation changed, reset to 0
    if previous_anim_name != anim_name:
        animation_frame = 0
        animation_timer = 0.0

    # update sprite animation and frame
    animation_timer += delta
    if animation_timer >= FRAME_SPEED:
        animation_timer -= FRAME_SPEED
        animation_frame = (animation_frame + 1) % ANIM_FRAMES[anim_name].size()
    frame = ANIM_FRAMES[anim_name][animation_frame]
    flip_h = direction == Vector2.RIGHT

func begin_duel():
    for npc in get_tree().get_nodes_in_group("npcs"):
        npc.behavior_paused = true
    exclamation.visible = true
    wait_timer.start(1.0)
    await wait_timer.finished
    target_position = player.position - (direction * World.TILE_SIZE)
    is_moving = true
    is_approaching_player = true
    await has_approached_player
    for line in pre_duel_dialog:
        dialogbox.open(line)
        await dialogbox.finished
    dialogbox.close()
    wait_timer.start(0.2)
    await wait_timer.finished
    for npc in get_tree().get_nodes_in_group("npcs"):
        npc.behavior_paused = false
