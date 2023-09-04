extends Node

var world = null

@onready var battle_scene = preload("res://battle/battle.tscn")

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
    if world == null:
        world = get_node("/root/world")

func start_battle():
    get_tree().paused = true

    # play transition
    world.transition.play_transition()
    var battle_instance = battle_scene.instantiate()
    if not world.transition.is_finished:
        await world.transition.finished

    # start battle
    var root = get_parent()
    root.remove_child(world)
    root.add_child(battle_instance)
    get_tree().paused = false
    battle_instance.battle_start()
    await battle_instance.finished

    # return to world
    root.remove_child(battle_instance)
    battle_instance.queue_free()
    root.add_child(world)
    world.transition.clear()
