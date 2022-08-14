extends Node2D

onready var party = get_node("/root/Party")

onready var dialog = $ui/dialog
onready var choose_action = $ui/choose_action
onready var choose_spell = $ui/choose_spell
onready var player_healthbar = $player_healthbar
onready var enemy_healthbar = $enemy_healthbar
onready var player_sprite = $player_sprite
onready var enemy_sprite = $enemy_sprite
onready var tween = $tween
onready var rng = RandomNumberGenerator.new()
onready var party_menu = $ui/party_menu
onready var item_menu = $ui/item_menu
onready var gem_sprite = $gem_sprite

onready var screen_rect = get_viewport_rect()

var player_familiar = null
var enemy_familiar = null

var actions = []

enum State {
    ENTER,
    CHOOSE_ACTION,
    CHOOSE_SPELL,
    ACTION,
    PLAYER_LOSS,
    PLAYER_WIN,
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

    party_menu.close(false)
    item_menu.close(false)
    rng.randomize()

    var raven_species = load("res://data/species/raven.tres")
    var firebolt = load("res://data/spells/fire_bolt.tres")
    var witchbolt = load("res://data/spells/witch_bolt.tres")
    enemy_familiar = Familiar.new(raven_species, 5)
    enemy_familiar.spells = [firebolt, witchbolt]

    next_state = State.ENTER

func _process(_delta):
    if next_state != null:
        var state = next_state
        next_state = null
        var state_function = "begin_" + State.keys()[state].to_lower()
        call(state_function)

func begin_enter():
    tween.interpolate_property(player_sprite, "position", Vector2(screen_rect.size.x + 56, player_sprite.position.y), player_sprite.position, 1.0)
    tween.interpolate_property(enemy_sprite, "position", Vector2(-56, enemy_sprite.position.y), enemy_sprite.position, 1.0)
    tween.start()
    enemy_sprite.set_familiar(enemy_familiar)

    yield(tween, "tween_all_completed")

    dialog.open_and_split("A wild " + enemy_familiar.get_name() + " appeared!")

    yield(dialog, "finished")

    open_enemy_healthbar()
    yield(player_summon(), "completed")
    next_state = State.CHOOSE_ACTION

func player_summon():
    player_familiar = party.familiars[0]
    dialog.open_and_split("You summon " + player_familiar.get_name() + "!")

    yield(dialog, "finished")
    player_sprite.set_familiar(player_familiar)
    open_player_healthbar()

func begin_choose_action():
    choose_action.open()

    yield(choose_action, "finished")
    if choose_action.choice == "SPELL":
        next_state = State.CHOOSE_SPELL
    elif choose_action.choice == "SUMMON":
        party_menu.context = PartyMenu.Context.SUMMON
        party_menu.open()
        yield(party_menu, "finished")
        if party_menu.switch_index == -1:
            next_state = State.CHOOSE_ACTION
        else:
            actions.append({
                "who": "player",
                "what": "summon",
                "switch_index": party_menu.switch_index
            })
            end_choose_action()
    elif choose_action.choice == "ITEM":
        item_menu.in_battle = true
        item_menu.open()
        yield(item_menu, "finished")
        open_player_healthbar()
        if item_menu.item_used:
            if item_menu.gem != null:
                actions.append({
                    "who": "player",
                    "what": "item",
                    "item": item_menu.gem
                })
            end_choose_action()
        else:
            next_state = State.CHOOSE_ACTION
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
        end_choose_action()

func end_choose_action():
    actions.append({
        "who": "enemy",
        "what": "spell",
        "spell": enemy_familiar.spells[1]
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
    # Note that the user of >= means that if both have equal speed, player goes first
    if action_speeds[0] >= action_speeds[1]:
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
    var attacker_healthbar
    var defender_healthbar
    var attacker_name
    var defender_name
    if is_player:
        attacker = player_familiar
        defender = enemy_familiar
        attacker_sprite = player_sprite
        defender_sprite = enemy_sprite
        attacker_healthbar = player_healthbar
        defender_healthbar = enemy_healthbar
        attacker_name = attacker.get_name()
        defender_name = "Enemy " + defender.get_name()
    else:
        attacker = enemy_familiar
        defender = player_familiar
        attacker_sprite = enemy_sprite
        defender_sprite = player_sprite
        attacker_healthbar = enemy_healthbar
        defender_healthbar = player_healthbar
        attacker_name = "Enemy " + attacker.get_name()
        defender_name = defender.get_name()

    if action.what == "spell":
        dialog.open_and_split(attacker_name + " used " + action.spell.name + "!")
        yield(dialog, "finished")
        attacker_sprite.animate_attack()
        yield(attacker_sprite, "finished")

        var damage = spell_compute_damage(attacker, defender, action.spell)
        defender.change_health(-damage)
        attacker.change_mana(-action.spell.cast_cost)

        defender_sprite.animate_hurt()
        attacker_healthbar.update()
        defender_healthbar.update()
        yield(defender_sprite, "finished")
        if not attacker_healthbar.is_finished():
            yield(attacker_healthbar, "finished")
        if not defender_healthbar.is_finished():
            yield(defender_healthbar, "finished")

        if defender.health == 0:
            yield(faint_familiar(defender_name, defender_sprite, defender_healthbar), "completed")
        if attacker.burnout != 0:
            yield(burnout_familiar(attacker, attacker_name, attacker_sprite, attacker_healthbar), "completed")
        if attacker.health == 0:
            yield(faint_familiar(attacker_name, attacker_sprite, attacker_healthbar), "completed")
    elif action.what == "summon":
        if action.who == "player":
            player_sprite.visible = false
            player_healthbar.visible = false
            party.swap_familiars(0, action.switch_index)
            yield(player_summon(), "completed")
    elif action.what == "item":
        if action.item.category == Item.Category.GEM:
            dialog.open_and_split("You used a " + action.item.name + "!")
            var health_mod = float(((3.0 * defender.max_health) - (2.0 * defender.health)) / (3.0 * defender.max_health)) # (3max_health - 2health) / 3max_health
            var gem_mod = 1.0 + (float(1) * 0.5) # 1 + (0.5 * gem_grade)
            var catch_rate = health_mod * gem_mod * defender.species.catch_rate
            var catch_value = rng.randf_range(0.0, 1.0)

            var catch_ticks: int = 3
            var catch_successful = catch_value <= catch_rate
            if not catch_successful:
                var tick_zone_size = (1 - catch_rate) / 4
                for zone in range(0, 4):
                    if catch_value < catch_rate + (tick_zone_size * (zone + 1)):
                        catch_ticks = 3 - zone
                        break

            gem_sprite.animate(action.item, catch_ticks, catch_successful)
            yield(gem_sprite, "finished")

            if catch_successful:
                dialog.open_and_split("Gotcha! " + enemy_familiar.get_name() + " was caught!")
                yield(dialog, "finished")
                next_state = null
                party.add_familiar(enemy_familiar)
                return
            else:
                dialog.open_and_split("Oh no! It broke free!")
                yield(dialog, "finished")

    if party.living_familiar_count() == 0:
        next_state = State.PLAYER_LOSS
    elif not enemy_familiar.is_living():
        next_state = State.PLAYER_WIN
    elif not player_familiar.is_living():
        party_menu.context = PartyMenu.Context.SUMMON
        party_menu.allow_back = false
        party_menu.open()
        yield(party_menu, "finished")
        party_menu.allow_back = true
        party.swap_familiars(0, party_menu.switch_index)
        yield(player_summon(), "completed")
        next_state = State.CHOOSE_ACTION
    elif actions.size() == 0:
        next_state = State.CHOOSE_ACTION
    else:
        next_state = State.ACTION

func spell_compute_damage(attacker, defender, spell) -> int:
    # Compute base damage
    var base_damage = (((((2 * attacker.level) / 5) + 2) * spell.power * (attacker.attack / defender.defense)) / 50) + 2

    # Compute STAB
    var stab = 1
    if attacker.species.type == spell.type:
        stab = 1.5

    # Compute weakness / resistance
    var type_mod = 1.0
    if Types.INFO[defender.species.type].weaknesses.has(spell.type):
        type_mod = 2.0
    elif Types.INFO[defender.species.type].resistances.has(spell.type):
        type_mod = 0.5

    var random = rng.randf_range(0.85, 1.0)
    return int(base_damage * stab * type_mod * random)

func faint_familiar(familiar_name, familiar_sprite, familiar_healthbar):
    familiar_sprite.animate_death()
    yield(familiar_sprite, "finished")
    familiar_healthbar.visible = false
    dialog.open_and_split(familiar_name + " fainted!")
    yield(dialog, "finished")

func burnout_familiar(familiar, familiar_name, familiar_sprite, familiar_healthbar):
    var burnout_damage = familiar.burnout * (ceil(familiar.level / 25.0) + 1)
    familiar.change_health(-burnout_damage)
    familiar_sprite.animate_hurt()
    familiar_healthbar.update()
    dialog.open_and_split(familiar_name + " burned out!")

    yield(dialog, "finished")
    if not familiar_sprite.is_finished():
        yield(familiar_sprite, "finished")
    if not familiar_healthbar.is_finished():
        yield(familiar_healthbar, "finished")

func open_enemy_healthbar():
    enemy_healthbar.set_familiar(enemy_familiar)
    enemy_healthbar.visible = true

func open_player_healthbar():
    player_healthbar.set_familiar(player_familiar)
    player_healthbar.visible = true

func begin_player_loss():
    dialog.open_and_split("You lose!")
    yield(dialog, "finished")
    next_state = null

func begin_player_win():
    dialog.open_and_split("You win!")
    yield(dialog, "finished")
    next_state = null
