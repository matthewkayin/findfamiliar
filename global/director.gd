extends Node

onready var battle_scene = preload("res://battle/battle.tscn")
var world_instance = null

func _ready():
    pass 

func start_battle(familiar: Familiar):
    var root = get_tree().get_root()
    world_instance = root.get_node("world")
    root.remove_child(world_instance)

    var battle_instance = battle_scene.instance()
    battle_instance.enemy_familiar = familiar
    root.add_child(battle_instance)
    yield(battle_instance, "finished")

    battle_instance.queue_free()
    root.add_child(world_instance)
