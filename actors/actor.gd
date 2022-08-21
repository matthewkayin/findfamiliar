extends Area2D
class_name Actor

signal took_step

onready var map = get_parent().get_node("tilemap")
onready var sprite = $sprite

const TILE_SIZE = Vector2(32, 32)

var facing_direction: Vector2 = Vector2.DOWN
var target_position = null
var paused: bool = false
var speed: int = 96

func _ready():
    add_to_group("actors")
    map.reserve_tile(position)

func is_moving():
    return target_position != null

func is_on_tile():
    return int(position.x) % 32 == 0 and int(position.y) % 32 == 0

func _physics_process(delta):
    _update(delta)

func _update(delta):
    move(delta)
    update_sprite()

func move(delta):
    if paused:
        return
    if is_moving():
        facing_direction = position.direction_to(target_position)
        var step_distance = speed * delta
        if position.distance_to(target_position) <= step_distance * 1.5:
            position = target_position
        else:
            position += facing_direction * step_distance
        if position == target_position:
            var old_position = position - (facing_direction * TILE_SIZE)
            map.free_tile(old_position)
            target_position = null
            emit_signal("took_step")

func try_move(direction: Vector2):
    var desired_target = position + (direction * TILE_SIZE)
    if map.is_tile_free(desired_target):
        target_position = desired_target
        map.reserve_tile(target_position)

func try_move_to(new_target_position: Vector2):
    if map.is_tile_free(new_target_position):
        target_position = new_target_position
        map.reserve_tile(new_target_position)
    else:
        print("try move to failed")

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
    if not is_moving(): 
        sprite.stop()
        sprite.frame = 0

    sprite.speed_scale = 96.0 / speed
    if sprite.is_playing() and not is_moving():
        sprite.speed_scale = 0.5

func pause():
    sprite.stop()
    paused = true

func resume():
    sprite.play()
    paused = false
