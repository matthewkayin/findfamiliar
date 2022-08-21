extends Node

onready var director = get_node("/root/Director")
onready var dialog = get_node("/root/world/ui/dialog")
onready var player = get_node("/root/world/player")
onready var tilemap = get_node("/root/world/tilemap")
onready var npc = get_parent()
onready var timer = $timer

export(Resource) var summoner
var has_battled = false

func _ready():
    pass

func _process(_delta):
    if not npc.is_pathing or player.interacting or has_battled:
        return
    if not player.is_on_tile() or not npc.is_on_tile():
        return
    if npc.position.direction_to(player.position) != npc.facing_direction:
        return
    var check_position = npc.position + (npc.facing_direction * 32)
    while check_position != player.position:
        if not tilemap.is_tile_free(check_position):
            return
        check_position += (npc.facing_direction * 32)
    player.interacting = true
    yield(npc.interact(), "completed")
    player.interacting = false

func play():
    if has_battled:
        var lines = dialog.split_lines([summoner.post_battle_dialog])
        for line in lines:
            dialog.open(line)
            yield(dialog, "finished")
    else:
        npc.sprite.frame = 0

        player.facing_direction = player.position.direction_to(npc.position)
        timer.start(1.0)
        yield(timer, "timeout")

        npc.try_move_to(player.position + (player.facing_direction * 32))
        yield(npc, "took_step")

        var lines = dialog.split_lines([summoner.opener])
        for line in lines:
            dialog.open(line)
            yield(dialog, "finished")

        director.start_battle({
            "type": "summoner",
            "summoner": summoner
        })
        yield(director, "battle_finished")

        has_battled = true
