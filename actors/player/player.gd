extends Actor

onready var pause_menu = get_parent().get_node("ui/pause_menu")
onready var move_input_timer = $move_input_timer

var input_direction: Vector2 = Vector2.ZERO
var interacting = false

func handle_input():
    if interacting:
        return

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
    elif Input.is_action_just_pressed("action"):
        if paused or is_moving():
            return
        var interact_position = position + (facing_direction * TILE_SIZE.x)
        for interactable in get_tree().get_nodes_in_group("interactables"):
            print(interact_position, " vs ", interactable.position)
            if interactable.position == interact_position and interactable.is_free_to_talk():
                interacting = true
                yield(interactable.interact(), "completed")
                interacting = false

func _update(delta):
    if paused and pause_menu.choice == ChoiceDialog.NONE:
        for actor in get_tree().get_nodes_in_group("actors"):
            actor.resume()
    handle_input()
    move(delta)
    update_sprite()

func move(delta):
    if paused:
        return
    .move(delta)
    if not is_moving() and move_input_timer.is_stopped() and input_direction != Vector2.ZERO:
        try_move(input_direction)

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
    if input_direction == Vector2.ZERO and not is_moving():
        sprite.stop()
        sprite.frame = 0

    sprite.speed_scale = 1
    if sprite.is_playing() and not is_moving():
        sprite.speed_scale = 0.5

func pause():
    sprite.stop()
    paused = true

func resume():
    sprite.play()
    paused = false
