extends Node2D

signal finished

onready var party = get_node("/root/Party")
onready var inventory = get_node("/root/Inventory")
onready var random = get_node("/root/Random")

onready var dialog = $ui/dialog
onready var choose_action = $ui/choose_action
onready var choose_spell = $ui/choose_spell
onready var player_healthbar = $player_healthbar
onready var enemy_healthbar = $enemy_healthbar
onready var player_gembar = $player_gembar
onready var enemy_gembar = $enemy_gembar
onready var player_sprite = $player_sprite
onready var enemy_sprite = $enemy_sprite
onready var tween = $tween
onready var timer = $timer
onready var party_menu = $ui/party_menu
onready var item_menu = $ui/item_menu
onready var gem_sprite = $gem_sprite
onready var nickname = $ui/nickname

onready var screen_rect = get_viewport_rect()

var player_familiar = null
var enemy_summoner = null
var enemy_familiar = null
var enemy_familiars = []
var is_summoner_battle = false
var actions = []
var participants = []
var escape_attempts = 0

enum State {
    ENTER,
    CHOOSE_ACTION,
    CHOOSE_SPELL,
    ACTION
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

    is_summoner_battle = enemy_summoner != null
    if is_summoner_battle:
        # Generate familiars from summoner party info
        for i in range(0, enemy_summoner.party_species.size()):
            var next_familiar = Familiar.new(enemy_summoner.party_species[i], enemy_summoner.party_level[i])
            for j in range(0, enemy_summoner.party_spells[i].size()):
                next_familiar.spells[j] = enemy_summoner.party_spells[i][j]
            enemy_familiars.append(next_familiar)
        enemy_familiar = enemy_familiars[0]
    elif enemy_familiar == null:
        var raven_species = load("res://data/species/raven.tres")
        var growl = load("res://data/spells/growl.tres")
        var firebolt = load("res://data/spells/fire_bolt.tres")
        var witchbolt = load("res://data/spells/witch_bolt.tres")
        enemy_familiar = Familiar.new(raven_species, 5)
        enemy_familiar.spells = [firebolt, growl, witchbolt, null]

    next_state = State.ENTER

func _process(_delta):
    if next_state != null:
        var state = next_state
        next_state = null
        var state_function = "begin_" + State.keys()[state].to_lower()
        call(state_function)

func start_sprite_movement(sprite, from, duration):
    var old_pos = sprite.position
    sprite.position = from
    sprite.offset = Vector2.ZERO
    sprite.region_rect.size = Vector2(56, 56)
    sprite.visible = true
    tween.interpolate_property(sprite, "position", from, old_pos, duration)

func begin_enter():
    player_sprite.texture = load("res://battle/summoners/player.png")
    player_sprite.visible = true

    if is_summoner_battle:
        enemy_sprite.texture = enemy_summoner.texture
        enemy_sprite.visible = true
        enemy_healthbar.visible = false
    else:
        enemy_sprite.set_familiar(enemy_familiar)

    start_sprite_movement(player_sprite, Vector2(screen_rect.size.x + 56, player_sprite.position.y), 1.0)
    start_sprite_movement(enemy_sprite, Vector2(-56, enemy_sprite.position.y), 1.0)
    tween.start()

    yield(tween, "tween_all_completed")

    player_gembar.open(party.familiars)
    if is_summoner_battle:
        enemy_gembar.open(enemy_familiars)
        dialog.open_and_split(enemy_summoner.name + " wants to battle!")
    else:
        dialog.open_and_split("A wild " + enemy_familiar.get_name() + " appeared!")

    yield(dialog, "finished")

    if is_summoner_battle:
        yield(enemy_summon(), "completed")
    else:
        open_enemy_healthbar()
    yield(player_summon(), "completed")
    next_state = State.CHOOSE_ACTION

func player_summon():
    player_gembar.visible = false
    player_familiar = party.familiars[0]
    dialog.open_and_split("You summon " + player_familiar.get_name() + "!")

    yield(dialog, "finished")
    player_sprite.set_familiar(player_familiar)
    open_player_healthbar()

func enemy_summon():
    enemy_gembar.visible = false
    enemy_familiar = enemy_familiars[0]
    dialog.open_and_split(enemy_summoner.name + " summoned " + enemy_familiar.get_name() + "!")

    yield(dialog, "finished")
    enemy_sprite.set_familiar(enemy_familiar)
    open_enemy_healthbar()

func is_enemy_wiped():
    if is_summoner_battle:
        var living_familiar_count = 0
        for familiar in enemy_familiars:
            if familiar.is_living():
                living_familiar_count += 1
        return living_familiar_count == 0
    return not enemy_familiar.is_living()

func begin_choose_action():
    choose_action.open()

    if not participants.has(player_familiar):
        participants.append(player_familiar)

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
    elif choose_action.choice == "REST":
        actions.append({
            "who": "player",
            "what": "rest"
        })
        end_choose_action()
    elif choose_action.choice == "RUN":
        actions.append({
            "who": "player",
            "what": "run"
        })
        end_choose_action()
    else:
        next_state = State.CHOOSE_ACTION

func begin_choose_spell():
    choose_spell.open_with(player_familiar.spells, player_familiar.mana)

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
    # If the player has no declared action, such as in the case where they used an item from the item menu
    if actions.size() == 0:
        # Then add a "none" action to the list. This allows player familiar to still be affected by status conditions
        actions.append({
            "who": "player",
            "what": "none"
        })
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
        if (action.what == "spell" or action.what == "rest") and action.who == "player":
            action_speeds.append(player_familiar.get_speed())
        elif (action.what == "spell" or action.what == "rest") and action.who == "enemy":
            action_speeds.append(enemy_familiar.get_speed())
        elif action.what == "item":
            action_speeds.append(300)
        elif action.what == "summon":
            action_speeds.append(301)
        elif action.what == "run":
            action_speeds.append(302)
        elif action.what == "none":
            action_speeds.append(303)
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
        if action.who == "player":
            escape_attempts = 0

        dialog.open_and_split(attacker_name + " used " + action.spell.name + "!")
        yield(dialog, "finished")

        var attack_accuracy_value = random.rng.randi_range(1, 100)
        var attack_hit = attack_accuracy_value <= action.spell.accuracy or action.spell.accuracy == -1

        if attack_hit:
            attacker_sprite.animate_attack()
            yield(attacker_sprite, "finished")

            attacker.change_mana(-action.spell.cast_cost)
            attacker_healthbar.update()

            if action.spell.power != 0:
                var result = spell_compute_damage(attacker, defender, action.spell)
                defender.change_health(-result.damage)
                defender_sprite.animate_hurt()
                defender_healthbar.update()

                if result.crit > 1.0:
                    dialog.open_and_split("A critical hit!")
                    yield(dialog, "finished")

                if result.effectiveness > 1.0:
                    dialog.open_and_split("It's super effective!")
                    yield(dialog, "finished")
                elif result.effectiveness < 1.0:
                    dialog.open_and_split("It's not very effective...")
                    yield(dialog, "finished")

                if not defender_sprite.is_finished():
                    yield(defender_sprite, "finished")
                if not defender_healthbar.is_finished():
                    yield(defender_healthbar, "finished")

            if not attacker_healthbar.is_finished():
                yield(attacker_healthbar, "finished")

            for i in range(0, action.spell.conditions.size()):
                var condition_apply_value = random.rng.randf_range(0.0, 1.0)
                if condition_apply_value > action.spell.condition_rates[i]:
                    continue
                var message = defender.add_condition(action.spell.conditions[i])
                defender_healthbar.refresh()
                if message != Conditions.INFO[action.spell.conditions[i]].noeffect_message or action.spell.power == 0:
                    dialog.open_and_split(defender.get_name() + message)
                    yield(dialog, "finished")

            if defender.health == 0:
                yield(faint_familiar(defender_name, defender_sprite, defender_healthbar), "completed")
                if action.who == "player":
                    yield(gain_experience(), "completed")
            if attacker.health == 0:
                yield(faint_familiar(attacker_name, attacker_sprite, attacker_healthbar), "completed")
        # elif not attack hit
        else:
            dialog.open_and_split(attacker_name + "'s attack missed!")
            yield(dialog, "finished")
            attacker.change_mana(-action.spell.cast_cost)
            attacker_healthbar.update()
            yield(attacker_healthbar, "finished")
    elif action.what == "summon":
        if action.who == "player":
            player_sprite.visible = false
            player_healthbar.visible = false
            player_familiar.clear_temp_conditions()
            party.swap_familiars(0, action.switch_index)
            yield(player_summon(), "completed")
            attacker = player_familiar
    elif action.what == "item":
        if action.who == "player":
            inventory.remove_item(action.item)
        if action.item.category == Item.Category.GEM:
            dialog.open_and_split("You used a " + action.item.name + "!")
            var health_mod = float(((3.0 * defender.max_health) - (2.0 * defender.health)) / (3.0 * defender.max_health)) # (3max_health - 2health) / 3max_health
            var gem_mod = 1.0 + (float(1) * 0.5) # 1 + (0.5 * gem_grade)
            var catch_rate = health_mod * gem_mod * defender.species.catch_rate
            var catch_value = random.rng.randf_range(0.0, 1.0)

            var catch_ticks: int = 3
            var catch_successful = catch_value <= catch_rate
            catch_successful = true
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
                nickname.open(enemy_familiar)
                yield(nickname, "finished")
                party.add_familiar(enemy_familiar)
                exit()
                return
            else:
                dialog.open_and_split("Oh no! It broke free!")
                yield(dialog, "finished")
    elif action.what == "rest":
        dialog.open_and_split(attacker_name + " took a rest.")
        attacker.change_mana(int(ceil(attacker.max_mana / 2)))
        attacker_healthbar.update()
        yield(attacker_healthbar, "finished")
        if not dialog.is_finished():
            yield(dialog, "finished")
    elif action.what == "run":
        var escape_odds = int((attacker.speed * 32) / (int(float(defender.speed) / 4.0) % 256)) + (30 * escape_attempts)
        var escape_value = random.rng.randi_range(0, 255)
        if escape_value <= escape_odds:
            dialog.open_and_split("Got away safely!")
            yield(dialog, "finished")
            exit()
            return
        else:
            escape_attempts += 1
            dialog.open_and_split("Can't escape!")
            yield(dialog, "finished")

    var is_battle_over = party.living_familiar_count() == 0 or not enemy_familiar.is_living()
    
    # Tick conditions
    for condition in attacker.conditions:
        if is_battle_over or not attacker.is_living():
            break
        if condition.ttl != Conditions.DURATION_INDEFINITE:
            condition.ttl -= 1
            if condition.ttl <= 0:
                var message = attacker.remove_condition(condition.type)
                attacker_healthbar.refresh()
                dialog.open_and_split(attacker.get_name() + message)
                yield(dialog, "finished")
                continue

    if party.living_familiar_count() == 0:
        exit()
    elif is_enemy_wiped():
        # Announce enemy lost
        dialog.open_and_split(enemy_summoner.name + " was defeated!")
        yield(dialog, "finished")

        # Pull enemy sprite into view
        enemy_sprite.texture = enemy_summoner.texture
        start_sprite_movement(enemy_sprite, Vector2(screen_rect.size.x + 56, enemy_sprite.position.y), 0.7)
        tween.start()
        yield(tween, "tween_all_completed")

        # Run enemy closer
        dialog.open_and_split(enemy_summoner.closer)
        yield(dialog, "finished")

        # Give player money
        dialog.open_and_split("A hundred bucks? Gee thanks!")
        yield(dialog, "finished")

        exit()
    elif not player_familiar.is_living():
        party_menu.context = PartyMenu.Context.SUMMON
        party_menu.allow_back = false
        party_menu.open()
        yield(party_menu, "finished")
        party_menu.allow_back = true
        party.swap_familiars(0, party_menu.switch_index)
        yield(player_summon(), "completed")
        next_state = State.CHOOSE_ACTION
    elif not enemy_familiar.is_living():
        var next_familiar = 1
        while not enemy_familiars[next_familiar].is_living():
            next_familiar += 1
        var temp = enemy_familiars[0]
        enemy_familiars[0] = enemy_familiars[next_familiar]
        enemy_familiars[next_familiar] = temp
        yield(enemy_summon(), "completed")
        next_state = State.CHOOSE_ACTION
    elif actions.size() == 0:
        next_state = State.CHOOSE_ACTION
    else:
        next_state = State.ACTION

func gain_experience():
    # Calculate gained experience
    var trainer_battle_mod = 1 # TODO equals 1.5 on trainer battle
    var exp_gained = int((enemy_familiar.species.base_exp_yield * enemy_familiar.level * trainer_battle_mod) / 7.0)
    dialog.open_and_split("Gained " + String(exp_gained) + " experience!")
    var was_level_up = false

    var other_level_up_messages = []
    for familiar in participants:
        if familiar == player_familiar:
            continue
        var familiar_level = familiar.level
        familiar.change_exp(exp_gained)
        for i in range(0, familiar.level - familiar_level):
            var level_gained = familiar_level + 1 + i
            other_level_up_messages.append(familiar.get_name() + " grew to level " + String(level_gained) + "!")
            was_level_up = true

    # Give exp to player's first familiar for the fancy bar effect
    var exp_left = exp_gained
    var TIME_PER_EXP = 0.01
    player_healthbar.set_exp_mode(true)
    while exp_left != 0:
        var exp_this_loop = 0
        if exp_left >= player_familiar.get_experience_left_for_level():
            exp_this_loop = player_familiar.get_experience_left_for_level()
        else:
            exp_this_loop = exp_left
        exp_left -= exp_this_loop

        tween.interpolate_property(player_familiar, "experience", player_familiar.experience, player_familiar.experience + exp_this_loop, exp_this_loop * TIME_PER_EXP)
        tween.start()
        yield(tween, "tween_all_completed")

        if player_familiar.get_experience_left_for_level() == 0:
            if not dialog.is_finished():
                yield(dialog, "finished")
            player_familiar.level += 1
            player_healthbar.update()
            dialog.open_and_split(player_familiar.get_name() + " grew to level " + String(player_familiar.level) + "!")
            yield(dialog, "finished")
            was_level_up = true
        elif was_level_up and other_level_up_messages.size() == 0:
            dialog.open("")
            yield(dialog, "finished")

    for message in other_level_up_messages:
        dialog.open_and_split(message)
        yield(dialog, "finished")
    if not was_level_up:
        yield(dialog, "finished")

    participants = []
    player_healthbar.set_exp_mode(false)
    player_healthbar.refresh()

func spell_compute_damage(attacker, defender, spell):
    # Compute base damage
    var base_damage = (((((2 * attacker.level) / 5) + 2) * spell.power * (attacker.get_attack() / defender.get_defense())) / 50) + 2

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

    # Compute crit
    var crit_mod = 1.0
    var crit_chance = attacker.speed / 2
    var crit_value = random.rng.randi_range(0, 255)
    if crit_value <= crit_chance:
        crit_mod = 2.0

    var random_mod = random.rng.randf_range(0.85, 1.0)
    return {
        "damage": int(base_damage * stab * type_mod * crit_mod * random_mod),
        "effectiveness": type_mod,
        "crit": crit_mod
    }

func faint_familiar(familiar_name, familiar_sprite, familiar_healthbar):
    if familiar_sprite == player_sprite:
        participants.erase(player_familiar)
    familiar_sprite.animate_death()
    yield(familiar_sprite, "finished")
    familiar_healthbar.visible = false
    dialog.open_and_split(familiar_name + " fainted!")
    yield(dialog, "finished")

func open_enemy_healthbar():
    enemy_healthbar.set_familiar(enemy_familiar)
    enemy_healthbar.visible = true

func open_player_healthbar():
    player_healthbar.set_familiar(player_familiar)
    player_healthbar.visible = true

func exit():
    next_state = null
    for familiar in party.familiars:
        familiar.do_post_battle_stuff()
    emit_signal("finished")
