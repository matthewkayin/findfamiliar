extends Node2D

onready var dialog = $ui/dialog
onready var choose_action = $ui/choose_action
onready var choose_spell = $ui/choose_spell
onready var player_healthbar = $player_healthbar
onready var enemy_healthbar = $enemy_healthbar
onready var player_sprite = $player_sprite
onready var enemy_sprite = $enemy_sprite
onready var tween = $tween

onready var screen_rect = get_viewport_rect()

var player_familiar = null
var enemy_familiar = null

var actions = []

enum State {
    ENTER,
    PLAYER_SUMMON,
    CHOOSE_ACTION,
    CHOOSE_SPELL,
    ACTION,
}

var next_state = null

func _ready():
    dialog.visible = false
    dialog.hide_on_close = false

    choose_action.visible = false
    choose_spell.close()
    player_healthbar.visible = false
    enemy_healthbar.visible = false
    player_sprite.visible = false
    enemy_sprite.visible = false

    var raven_species = load("res://data/species/raven.tres")
    var firebolt = load("res://data/spells/fire_bolt.tres")
    var witchbolt = load("res://data/spells/witch_bolt.tres")
    player_familiar = Familiar.new(raven_species, 5)
    player_familiar.spells = [firebolt, witchbolt]
    enemy_familiar = Familiar.new(raven_species, 5)
    enemy_familiar.spells = [firebolt, witchbolt]
    player_familiar.nickname = "Maves"

    next_state = State.ENTER

func _process(_delta):
    if next_state != null:
        var state = next_state
        next_state = null
        if state == State.ENTER:
            begin_enter()
        elif state == State.PLAYER_SUMMON:
            begin_player_summon()
        elif state == State.CHOOSE_ACTION:
            begin_choose_action()
        elif state == State.CHOOSE_SPELL:
            begin_choose_spell()
        elif state == State.ACTION:
            begin_action()

func begin_enter():
    tween.interpolate_property(player_sprite, "position", Vector2(screen_rect.size.x + 56, player_sprite.position.y), player_sprite.position, 1.0)
    tween.interpolate_property(enemy_sprite, "position", Vector2(-56, enemy_sprite.position.y), enemy_sprite.position, 1.0)
    tween.start()
    enemy_sprite.set_familiar(enemy_familiar)

    yield(tween, "tween_all_completed")

    dialog.open_and_split("A wild raven appeared!")

    yield(dialog, "finished")

    open_enemy_healthbar()
    next_state = State.PLAYER_SUMMON

func begin_player_summon():
    dialog.open("You summon\nfriend!")

    yield(dialog, "finished")
    player_sprite.set_familiar(player_familiar)
    open_player_healthbar()
    next_state = State.CHOOSE_ACTION

func begin_choose_action():
    choose_action.open()

    yield(choose_action, "finished")
    if choose_action.choice == "SPELL":
        next_state = State.CHOOSE_SPELL
    else:
        next_state = State.CHOOSE_ACTION

func begin_choose_spell():
    choose_spell.open_with(player_familiar.spells)

    yield(choose_spell, "finished")
    if choose_spell.choice == ChoiceDialog.NONE:
        next_state = State.CHOOSE_ACTION
    else:
        actions.append({
            "who": "player",
            "what": "spell",
            "spell": player_familiar.spells[choose_spell.cursor_index.y]
        })
        actions.append({
            "who": "enemy",
            "what": "spell",
            "spell": enemy_familiar.spells[0]
        })
        next_state = State.ACTION

func get_fastest_action():
    if actions.size() == 1:
        return 0

    var action_speeds = []
    for action in actions:
        if action.what == "spell" and action.who == "player":
            action_speeds.append(player_familiar.speed)
        elif action.what == "spell" and action.who == "enemy":
            action_speeds.append(enemy_familiar.speed)
        elif action.what == "item":
            action_speeds.append(300)
        elif action.what == "summon":
            action_speeds.append(301)
        elif action.what == "run":
            action_speeds.append(302)
    # Note that the user of <= means that if both have equal speed, player goes first
    if action_speeds[0] <= action_speeds[1]:
        return 0
    else:
        return 1

func begin_action():
    var action_index = get_fastest_action()
    var action = actions[action_index]
    actions.remove(action_index)

    var is_player = action.who == "player"
    var attacker
    var defender
    var attacker_sprite
    var defender_sprite
    var attacker_name
    var defender_name
    if is_player:
        attacker = player_familiar
        defender = enemy_familiar
        attacker_sprite = player_sprite
        defender_sprite = enemy_sprite
        attacker_name = attacker.get_name()
        defender_name = "Enemy " + defender.get_name()
    else:
        attacker = enemy_familiar
        defender = player_familiar
        attacker_sprite = enemy_sprite
        defender_sprite = player_sprite
        attacker_name = "Enemy " + attacker.get_name()
        defender_name = defender.get_name()

    if action.what == "spell":
        dialog.open_and_split(attacker_name + " used " + action.spell.name + "!")
        yield(dialog, "finished")
        attacker_sprite.animate_attack()
        yield(attacker_sprite, "finished")
        defender_sprite.animate_hurt()
        yield(defender_sprite, "finished")

    if actions.size() == 0:
        next_state = State.CHOOSE_ACTION
    else:
        next_state = State.ACTION

func open_enemy_healthbar():
    enemy_healthbar.set_familiar(enemy_familiar)
    enemy_healthbar.visible = true

func open_player_healthbar():
    player_healthbar.set_familiar(player_familiar)
    player_healthbar.visible = true
