extends Node

var world = null

@onready var battle_scene = preload("res://battle/battle.tscn")

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

    var config = ConfigFile.new()
    var err = config.load("user://settings.ini")
    print(OS.get_user_data_dir())
    if err == OK:
        var window_size = config.get_value("settings", "resolution").split("x")
        get_window().set_size(Vector2(int(window_size[0]), int(window_size[1])))
    else:
        var resolution_str = str(get_window().size.x) + "x" + str(get_window().size.y)
        config.set_value("settings", "resolution", resolution_str)
        config.save("user://settings.ini")

    var species_cat = load("res://familiar/species/catsith.tres")
    var item_gem = load("res://familiar/items/gem.tres")
    var item_potion = load("res://familiar/items/potion.tres")

    player_party.familiars.append(Familiar.new(species_cat, 6))
    player_party.familiars[0].nickname = "Jiji"

    player_party.add_item(item_gem, 5)
    player_party.add_item(item_potion, 10)

func _process(_delta):
    if world == null:
        world = get_node_or_null("/root/world")

func start_battle(is_witch_battle: bool = false):
    get_tree().paused = true

    # play transition
    world.transition.play_transition()
    var battle_instance = battle_scene.instantiate()
    if not world.transition.is_finished:
        await world.transition.finished

    # start battle
    var root = get_parent()
    root.remove_child(world)
    battle_instance.test_battle = false
    root.add_child(battle_instance)
    get_tree().paused = false
    battle_instance.battle_start(is_witch_battle)
    await battle_instance.finished

    # return to world
    root.remove_child(battle_instance)
    battle_instance.queue_free()
    root.add_child(world)
    world.transition.clear()

func enter_world(path: String, entrance_id: int):
    world.player.sprite.visible = false
    await world.transition.fade_out()

    var root = get_parent()
    var old_world = world
    world = load(path).instantiate()
    world.spawn_player(entrance_id, old_world.player.direction)
    root.remove_child(old_world)
    root.add_child(world)
    old_world.queue_free()
