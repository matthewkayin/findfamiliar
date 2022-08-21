extends Node

signal battle_finished

onready var battle_scene = preload("res://battle/battle.tscn")
var world_instance = null

func _ready():
    pass 

func start_battle(params):
    var root = get_tree().get_root()
    world_instance = root.get_node("world")
    root.remove_child(world_instance)

    var battle_instance = battle_scene.instance()
    if params.type == "wild":
        battle_instance.enemy_familiar = params.familiar
    elif params.type == "summoner":
        battle_instance.enemy_summoner = params.summoner
    root.add_child(battle_instance)
    yield(battle_instance, "finished")

    battle_instance.queue_free()
    root.add_child(world_instance)

    emit_signal("battle_finished")
