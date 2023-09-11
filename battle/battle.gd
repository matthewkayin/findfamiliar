extends Node2D
class_name Battle

signal finished
signal resume_round

@onready var player_party = get_node("/root/player_party")
@onready var enemy_party = get_node("/root/enemy_party")

@onready var animator = $animator
@onready var dialog = $dialog
@onready var battle_actions = $battle_actions
@onready var spell_chooser = $spell_chooser
@onready var party_menu = $party_menu
@onready var item_chooser = $item_chooser
@onready var player_sprite = $player_sprite
@onready var enemy_sprite = $enemy_sprite
@onready var player_healthbar = $player_healthbar
@onready var enemy_healthbar = $enemy_healthbar
@onready var gem_sprite = $gem_sprite
@onready var exp_timer = $exp_timer
@onready var whiteout = $whiteout

enum ActionActor {
    PLAYER = 0,
    ENEMY = 1
}

enum ActionType {
    NONE,
    SPELL,
    SWITCH,
    ITEM,
    RUN
}

var test_battle: bool = true
@export var player_familiars: Array[WitchFamiliar]
@export var test_is_duel: bool = false
@export var enemy_familiars: Array[WitchFamiliar]

var is_duel: bool = false
var player_escape_attempts: int = 0
var choosing_item_target: bool = false

func _ready():
    party_menu.clear_warning.connect(dialog.clear)

    if test_battle:
        player_party.familiars.clear()
        for witch_familiar in player_familiars:
            var familiar = Familiar.new(witch_familiar.species, witch_familiar.level)
            if witch_familiar.override_spells:
                familiar.spells.clear()
                for i in range(0, 4):
                    var witch_familiar_spell = witch_familiar["spell" + str(i + 1)]
                    if witch_familiar_spell == null:
                        continue
                    familiar.spells.append(witch_familiar_spell)
            player_party.familiars.append(familiar)
        is_duel = test_is_duel
        enemy_party.familiars.clear()
        for witch_familiar in enemy_familiars:
            var familiar = Familiar.new(witch_familiar.species, witch_familiar.level)
            if witch_familiar.override_spells:
                familiar.spells.clear()
                for i in range(0, 4):
                    var witch_familiar_spell = witch_familiar["spell" + str(i + 1)]
                    if witch_familiar_spell == null:
                        continue
                    familiar.spells.append(witch_familiar_spell)
            enemy_party.familiars.append(familiar)
            if not is_duel:
                break
        enemy_party.enemy_witch_name = "TEST FRIEND"
        enemy_party.enemy_lose_message = "Ack, I lost."
        enemy_party.enemy_witch_sprite = load("res://battle/sprites/witches/frida.png")
        battle_start()

func battle_start(is_witch_battle: bool = false):
    is_duel = is_witch_battle

    player_party.before_battle()
    enemy_party.before_battle()

    dialog.clear()
    dialog.visible = true
    await animator.animate_enter(is_duel)
    if is_duel:
        dialog.open(enemy_party.enemy_witch_name + "\nchallenged you to a duel!")
        await dialog.finished
        dialog.clear()
        await summon_familiar(ActionActor.ENEMY, true)
    else:
        enemy_healthbar.open()
        dialog.open("A wild " + enemy_party.familiars[0].get_display_name() + " appeared!")
        await dialog.finished
        dialog.clear()

    await summon_familiar(ActionActor.PLAYER, true)
    dialog.clear()

    battle_actions_open()

func battle_actions_open(remember_cursor: bool = false):
    dialog.set_text("What will\n" + player_party.familiars[0].get_display_name() + " do?") 
    battle_actions.open(remember_cursor)

func summon_familiar(who: ActionActor, animate_exit: bool = false):
    var party = player_party if who == ActionActor.PLAYER else enemy_party
    var message = "You " if who == ActionActor.PLAYER else enemy_party.enemy_witch_name + "\n"
    message += "summoned " + party.familiars[0].get_display_name() + "!"

    dialog.open(message)
    if animate_exit:
        if who == ActionActor.PLAYER:
            await animator.animate_player_exit()
        else:
            await animator.animate_enemy_exit()
    await animator.animate_summon(who)
    if not dialog.is_finished:
        await dialog.finished
    dialog.clear()

func _process(_delta):
    # BATTLE ACTIONS
    if battle_actions.is_open() and battle_actions.finished:
        if battle_actions.choice == "SPELL":
            var spell_options: Array[String] = []
            for spell in player_party.familiars[0].spells:
                spell_options.append(spell.name)
            spell_chooser.open_with(spell_options)
            battle_actions.close()
        elif battle_actions.choice == "SWITCH":
            battle_actions.close()
            party_menu.open()
        elif battle_actions.choice == "ITEM":
            battle_actions.close()
            item_chooser.open(player_party.items)
        elif battle_actions.choice == "RUN":
            if is_duel:
                battle_actions.close()
                dialog.open("There's no running\nfrom a witch duel!")
                await dialog.finished
                dialog.clear()
                battle_actions_open(true)
            else:
                do_round({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.RUN
                })
                battle_actions.close()
        return

    # SPELL CHOOSER
    if spell_chooser.is_open() and spell_chooser.finished:
        # return to battle actions
        if spell_chooser.choice == "":
            battle_actions_open()
            spell_chooser.close()
        else:
            # get chosen spell
            var chosen_spell: Spell = null
            for spell in player_party.familiars[0].spells:
                if spell_chooser.choice == spell.name:
                    chosen_spell = spell
                    break
            # use spell
            spell_chooser.close()
            do_round({
                "actor": ActionActor.PLAYER,
                "type": ActionType.SPELL,
                "spell": chosen_spell
            })
        return

    # PARTY MENU
    if party_menu.is_open() and party_menu.is_finished and not choosing_item_target and not party_menu.is_interpolating:
        if party_menu.choice == -1:
            party_menu.close()
            battle_actions_open(true)
        elif not player_party.familiars[party_menu.choice].is_living():
            dialog.set_text_fancy(player_party.familiars[party_menu.choice].get_display_name() + " is out\nof energy!", dialog.CHAR_SPEED_POPUP)
            party_menu.is_finished = false
        elif party_menu.choice == 0:
            dialog.set_text_fancy(player_party.familiars[0].get_display_name() + " is already\nfighting!", dialog.CHAR_SPEED_POPUP)
            party_menu.is_finished = false
        else:
            if player_party.familiars[0].is_living():
                party_menu.close()
                do_round({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.SWITCH,
                    "index": party_menu.choice,
                })
            else:
                party_menu.close()
                player_party.switch(0, party_menu.choice)
                await summon_familiar(ActionActor.PLAYER)
                emit_signal("resume_round")
        return

    # ITEM MENU
    if item_chooser.is_open() and item_chooser.finished:
        var chosen_item: Item = item_chooser.choice
        # return to battle actions
        if chosen_item == null:
            item_chooser.close()
            battle_actions_open(true)
        else:
            # warn player they can't use gem
            if chosen_item.type == Item.ItemType.GEM and is_duel:
                dialog.set_text_fancy("You can't catch someone else's\nfamiliar!", dialog.CHAR_SPEED_POPUP)
                item_chooser.finished = false
            # use gem
            elif chosen_item.type == Item.ItemType.GEM:
                dialog.clear()
                item_chooser.close()
                player_party.remove_item(chosen_item)
                do_round({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.ITEM,
                    "item": chosen_item
                })
            elif chosen_item.type == Item.ItemType.HEALING:
                item_chooser.close()
                choosing_item_target = true
                party_menu.open()
        return

    # PARTY MENU USING ITEM
    if choosing_item_target and party_menu.is_open() and party_menu.is_finished and not party_menu.is_interpolating:
        if party_menu.choice == -1:
            party_menu.close()
            item_chooser.open(player_party.items, true)
            choosing_item_target = false
        elif not player_party.familiars[party_menu.choice].is_living():
            dialog.set_text_fancy(player_party.familiars[party_menu.choice].get_display_name() + " is out\nof energy!", dialog.CHAR_SPEED_POPUP)
            party_menu.is_finished = false
        else:
            # use the item
            player_party.use_item(item_chooser.choice, party_menu.choice)

            # animate health change in party menu
            await party_menu.update_health()

            # close menus
            party_menu.close()
            item_chooser.close()
            player_healthbar.fast_update()
            choosing_item_target = false

            do_round({
                "actor": ActionActor.PLAYER,
                "type": ActionType.NONE
            })
        return

func enemy_choose_action():
    var spell = enemy_party.familiars[0].spells[randi_range(0, enemy_party.familiars[0].spells.size() - 1)]
    return {
        "actor": ActionActor.ENEMY,
        "type": ActionType.SPELL,
        "spell": spell
    }

func do_round(player_action):
    # enemy chooses action
    var enemy_action = enemy_choose_action()

    # determine turn order
    var player_first: bool
    if player_action.type == ActionType.RUN or player_action.type == ActionType.SWITCH or player_action.type == ActionType.ITEM:
        player_first = true
    elif enemy_action.type == ActionType.RUN or enemy_action.type == ActionType.SWITCH or enemy_action.type == ActionType.ITEM:
        player_first = false
    elif player_action.spell.priority > enemy_action.spell.priority:
        player_first = true
    elif player_action.spell.priority < enemy_action.spell.priority:
        player_first = false
    elif player_party.familiars[0].get_agility() == enemy_party.familiars[0].get_agility():
        player_first = randi_range(0, 1) == 0
    else:
        player_first = player_party.familiars[0].get_agility() > enemy_party.familiars[0].get_agility()

    # do each turn
    var actions = [player_action, enemy_action] if player_first else [enemy_action, player_action]
    for turn_number in range(0, actions.size()):
        await do_action(actions[turn_number])
        var skip_next_turn: bool = false

        # check if player familiar is dead
        if not player_party.familiars[0].is_living():
            dialog.open(player_party.familiars[0].get_display_name() + " was defeated!")
            await animator.animate_faint(ActionActor.PLAYER)
            if not dialog.is_finished:
                await dialog.finished
            player_healthbar.close()
            dialog.clear()
        # check if enemy familiar is dead
        if not enemy_party.familiars[0].is_living():
            dialog.open("Enemy " + enemy_party.familiars[0].get_display_name() + " was defeated!")
            await animator.animate_faint(ActionActor.ENEMY)
            if not dialog.is_finished:
                await dialog.finished
            enemy_healthbar.close()
            dialog.clear()

        # player party defeated
        if player_party.is_defeated():
            dialog.open("All of your familiars\nhave been defeated!")
            await dialog.finished
            battle_end()
            return
        # enemy party defeated
        if enemy_party.is_defeated():
            if is_duel:
                dialog.open("You defeated\n" + enemy_party.enemy_witch_name + "!")
                await dialog.finished
                dialog.clear()
                await animator.animate_enemy_reenter()
                dialog.open(enemy_party.enemy_lose_message)
                await dialog.finished
                dialog.clear()

            # calculate exp gained
            var exp_yield: float = 0.0
            for i in range(0, enemy_party.familiars.size()):
                exp_yield += float(enemy_party.familiars[i].species.exp_yield * enemy_party.familiars[i].level) / 7.0
            if is_duel:
                exp_yield *= 1.5

            # divide it up among party familiars
            var divided_exp_yield: int = int(exp_yield / player_party.get_living_familiar_count())
            var exp_yield_remainder: int = int(exp_yield) % player_party.get_living_familiar_count()
            var exp_each: Array[int] = []
            for i in range(0, player_party.familiars.size()):
                if not player_party.familiars[i].is_living() or not player_party.familiars[i].has_participated:
                    exp_each.append(0)
                    continue
                exp_each.append(divided_exp_yield)
                if i == 0:
                    exp_each[i] += exp_yield_remainder

            dialog.open("You gained\n" + str(int(exp_yield)) + " EXP. Points!")
            party_menu.open(false, true)

            var exp_finished = false
            while not exp_finished:
                exp_timer.start(0.025)
                await exp_timer.timeout
                exp_finished = true
                for i in range(0, player_party.familiars.size()):
                    if exp_each[i] > 0:
                        exp_each[i] -= 1
                        var leveled_up = player_party.familiars[i].give_exp(1)
                        if leveled_up:
                            # announce level up
                            dialog.open(player_party.familiars[i].get_display_name() + " grew to\nlevel " + str(player_party.familiars[i].level) + "!")
                            await dialog.finished
                            dialog.clear()

                            # check for any learned spells
                            for learn_spell in player_party.familiars[i].species.learn_spells:
                                if learn_spell.level == player_party.familiars[i].level:
                                    if player_party.familiars[i].spells.size() == 4:
                                        # TODO have players choose which move to forget
                                        pass
                                    else:
                                        player_party.familiars[i].spells.append(learn_spell)
                                        dialog.open(player_party.familiars[i].get_display_name() + " learned " + learn_spell.name + "!")
                                        await dialog.finished
                                        dialog.clear()
                        if exp_each[i] > 0:
                            exp_finished = false
            if dialog.is_finished:
                dialog.open("")
            await dialog.finished
            battle_end()
            return
        # end enemy party defeated

        # switch
        if not player_party.familiars[0].is_living():
            party_menu.open(false)
            await resume_round
            if turn_number == 0 and actions[1].actor == ActionActor.PLAYER:
                skip_next_turn = true
        if not enemy_party.familiars[0].is_living():
            # TODO enemy switch
            if turn_number == 0 and actions[1].actor == ActionActor.ENEMY:
                skip_next_turn = true
        var player_catch_successful = gem_sprite.visible
        if player_catch_successful:
            skip_next_turn = true
        
        if skip_next_turn:
            break
    # end for action in actions

    # open action menu for player's next turn
    battle_actions_open()

func do_action(action):
    # SPELL
    if action.type == ActionType.SPELL:
        # setup attacker and defender
        var attacker: Familiar = player_party.familiars[0] if action.actor == ActionActor.PLAYER else enemy_party.familiars[0]
        var defender: Familiar = enemy_party.familiars[0] if action.actor == ActionActor.PLAYER else player_party.familiars[0]
        var attacker_healthbar = player_healthbar if action.actor == ActionActor.PLAYER else enemy_healthbar
        var defender_healthbar = enemy_healthbar if action.actor == ActionActor.PLAYER else player_healthbar

        # display spell message
        var message = ""
        if action.actor == ActionActor.ENEMY:
            message += "Enemy "
        message += attacker.get_display_name() + " used\n" + action.spell.name + "!"
        dialog.open(message)
        await dialog.finished
        dialog.clear()

        # check if move hits
        var spell_hit: bool = false
        if action.spell.damage_type != Spell.DamageType.NONE:
            var accuracy_dc: int = action.spell.accuracy + (float(attacker.get_agility() - defender.get_agility()) / 1.5)
            spell_hit = randi_range(0, 100) <= accuracy_dc
        # check if condition hit
        var condition_hit: bool = false
        var condition_dc: int = action.spell.condition_accuracy
        if defender.is_living() and action.spell.condition_target == Spell.ConditionTarget.OPPONENT:
            condition_dc += int(float(attacker.get_intellect() - defender.get_intellect()) / 1.5)
            condition_hit = randi_range(0, 100) <= condition_dc
        elif action.spell.condition_target == Spell.ConditionTarget.SELF: 
            condition_hit = true

        # display miss message
        if (not spell_hit and action.spell.damage_type != Spell.DamageType.NONE) or (not condition_hit and action.spell.damage_type == Spell.DamageType.NONE):
            var miss_message = ""
            if action.actor == ActionActor.ENEMY:
                miss_message += "Enemy "
            miss_message += attacker.get_display_name() + "'s attack missed!"
            dialog.open(miss_message)
            await dialog.finished
            dialog.clear()
        else:
            await animator.animate_spell(action.actor, action.spell)

        if spell_hit:
            # Compute base damage
            var attacker_attack: float = attacker.get_strength() if action.spell.damage_type == Spell.DamageType.PHYSICAL else attacker.get_intellect()
            var defender_defense: float = defender.get_defense() if action.spell.damage_type == Spell.DamageType.PHYSICAL else defender.get_intellect()
            var base_damage: float = (((((2.0 * attacker.level) / 5.0) + 2.0) * action.spell.power * (attacker_attack / defender_defense)) / 50.0) + 2.0

            # Compute STAB
            var stab: float = 1
            if attacker.species.type == action.spell.type:
                stab = 1.5

            # Compute weakness / resistance
            var type_mod: float = 1.0
            if Types.INFO[defender.species.type].weaknesses.has(action.spell.type):
                type_mod = 2.0
            elif Types.INFO[defender.species.type].resistances.has(action.spell.type):
                type_mod = 0.5

            # Compute crit
            var crit_mod: float = 1.0
            var crit_chance: int = int(attacker.get_agility() / 2.0)
            var crit_value: int = randi_range(0, 255)
            if action.spell.damage_type == Spell.DamageType.PHYSICAL and crit_value <= crit_chance:
                crit_mod = 2.0

            var random_mod: float = randf_range(0.85, 1.0)
            var damage = int(base_damage * stab * type_mod * crit_mod * random_mod)

            defender.health = max(defender.health - damage, 0)

            defender_healthbar.update()
            await animator.animate_hurt((action.actor + 1) % 2, type_mod)
            if crit_mod == 2.0:
                dialog.open("Critical hit!")
                await dialog.finished
                dialog.clear()
            if type_mod == 2.0:
                dialog.open("It's super effective!")
                await dialog.finished
                dialog.clear()
            if type_mod == 0.5:
                dialog.open("It's not very effective...")
                await dialog.finished
                dialog.clear()
            if defender_healthbar.is_interpolating:
                await defender_healthbar.finished

        # SPELL CONDITIONS

        if condition_hit:
            var condition_target = attacker if action.spell.condition_target == Spell.ConditionTarget.SELF else defender
            var condition_target_name = condition_target.get_display_name() if condition_target == player_party.familiars[0] else "Enemy " + condition_target.get_display_name()
            var condition_target_healthbar = attacker_healthbar if action.spell.condition_target == Spell.ConditionTarget.SELF else defender_healthbar

            # handle stats
            for stat_name in Familiar.STAT_NAMES:
                var stat_mod = action.spell[stat_name + "_mod"]
                if stat_mod == 0:
                    continue

                var target_current_stage = condition_target[stat_name + "_stage"]
                if stat_mod > 0 and target_current_stage == 6:
                    dialog.open(condition_target_name + "'s " + stat_name.to_upper() + "\nwon't go any higher!")
                    await dialog.finished
                    dialog.clear()
                    continue
                if stat_mod < 0 and target_current_stage == -6:
                    dialog.open(condition_target_name + "'s " + stat_name.to_upper() + "\nwon't go any lower!")
                    await dialog.finished
                    dialog.clear()
                    continue

                var stat_verb = "rose" if stat_mod > 0 else "fell"
                condition_target[stat_name + "_stage"] = clamp(target_current_stage + stat_mod, -6, 6)
                condition_target_healthbar.refresh()
                dialog.open(condition_target_name + "'s\n" + stat_name.to_upper() + " " + stat_verb + "!")
                await dialog.finished
                dialog.clear()
            if action.spell.condition != Condition.Type.NONE:
                if condition_target.condition != Condition.Type.NONE and action.spell.damage_type == Spell.DamageType.NONE:
                    dialog.open("But it failed!")
                    await dialog.finished
                    dialog.clear()
                if condition_target.condition == Condition.Type.NONE:
                    condition_target.condition = action.spell.condition
                    condition_target_healthbar.update()
                    animator.animate_condition(ActionActor.ENEMY if action.actor == ActionActor.PLAYER else ActionActor.PLAYER, action.spell.condition)
                    dialog.open(condition_target_name + Condition.INFO[action.spell.condition].apply_message)
                    if not dialog.is_finished:
                        await dialog.finished
                    dialog.clear()
    # SWITCH
    elif action.type == ActionType.SWITCH:
        var attacker_party = player_party if action.actor == ActionActor.PLAYER else enemy_sprite

        await animator.animate_unsummon(action.actor)

        player_party.familiars[0].clear_stat_mods()
        attacker_party.switch(0, action.index)

        var delay_tween = get_tree().create_tween()
        delay_tween.tween_interval(0.25)
        await delay_tween.finished
        await summon_familiar(action.actor)
    # TRY TO CATCH FAMILIAR
    elif action.type == ActionType.ITEM and action.item.type == Item.ItemType.GEM:
        var familiar = enemy_party.familiars[0]
        var catch_dc: int = int(max(familiar.species.catch_rate * ((((3.0 * familiar.max_health) - (2.0 * familiar.health)) / (3.0 * familiar.max_health))), 1))
        var catch_roll: int = randi_range(0, 255)
        var catch_successful = catch_roll < catch_dc
        var num_ticks = 3
        if not catch_successful:
            var miss_range: float = (255 - catch_dc) / 3.0
            if catch_roll < catch_dc + miss_range:
                num_ticks = 3
            elif catch_roll < catch_dc + (2.0 * miss_range):
                num_ticks = 2
            else:
                num_ticks = 1
        await gem_sprite.animate_throw()
        await animator.animate_unsummon(ActionActor.ENEMY)
        await gem_sprite.animate_fall()
        await gem_sprite.animate_ticks(num_ticks)

        if catch_successful:
            gem_sprite.play("catch")

            dialog.open("Gotcha! " + familiar.get_display_name() + "\nwas caught!")
            await dialog.finished
            battle_end()
        else:
            gem_sprite.visible = false
            await animator.animate_summon(ActionActor.ENEMY)

            dialog.open("It broke free!")
            await dialog.finished
    # RUN
    elif action.type == ActionType.RUN:
        player_escape_attempts += 1
        var escape_successful = player_party.familiars[0].get_agility() >= enemy_party.familiars[0].get_agility()
        if not escape_successful:
            var escape_odds = floor((player_party.familiars[0].get_agility() * 32.0) / (int(enemy_party.familiars[0].get_agility() / 4.0) % 256)) + (30 * player_escape_attempts)
            escape_successful = escape_odds > 255 or randi_range(0, 255) < escape_odds
        
        if escape_successful:
            dialog.open("Got away safely!")
            await dialog.finished
            dialog.clear()
            battle_end()
        else:
            dialog.open("Can't escape!")
            if not dialog.is_finished:
                await dialog.finished
            dialog.clear()

    # reset escape attempts
    if action.actor == ActionActor.PLAYER and action.type != ActionType.RUN:
        player_escape_attempts = 0

    # update battle flag
    var familiar = player_party.familiars[0] if action.actor == ActionActor.PLAYER else enemy_party.familiars[0]
    familiar.has_participated = true

    # apply burn damage
    if familiar.condition == Condition.Type.BURNED:
        var healthbar = player_healthbar if action.actor == ActionActor.PLAYER else enemy_healthbar
        familiar.health = max(familiar.health - int(familiar.max_health / 8.0), 0)
        healthbar.update()

        var burn_message = ""
        if action.actor == ActionActor.ENEMY:
            burn_message += "Enemy "
        burn_message += familiar.get_display_name() + "\ntook burn damage!"
        dialog.open(burn_message)
        await dialog.finished
        dialog.clear()
    elif familiar.condition == Condition.Type.POISONED:
        var healthbar = player_healthbar if action.actor == ActionActor.PLAYER else enemy_healthbar
        familiar.health = max(familiar.health - int(familiar.max_health / 8.0), 0)
        healthbar.update()

        var poison_message = ""
        if action.actor == ActionActor.ENEMY:
            poison_message += "Enemy "
        poison_message += familiar.get_display_name() + "\ntook poison damage!"
        dialog.open(poison_message)
        await animator.animate_condition(action.actor, familiar.condition)
        if not dialog.is_finished:
            await dialog.finished
        dialog.clear()

func battle_end():
    var whiteout_tween = get_tree().create_tween()
    whiteout_tween.tween_property(whiteout, "modulate", Color(1, 1, 1, 1), 0.5)
    await whiteout_tween.finished
    player_party.after_battle()
    emit_signal("finished")
