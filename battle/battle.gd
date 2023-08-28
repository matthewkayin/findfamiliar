extends Node2D
class_name Battle

signal resume_round

@onready var player_party = get_node("/root/player_party")
@onready var enemy_party = get_node("/root/enemy_party")

@onready var animator = $animator
@onready var dialog = $dialog
@onready var battle_actions = $battle_actions
@onready var spell_chooser = $spell_chooser
@onready var party_menu = $party_menu
@onready var party_warning = $party_warning
@onready var item_chooser = $item_chooser
@onready var item_warning = $item_warning
@onready var player_sprite = $player_sprite
@onready var enemy_sprite = $enemy_sprite
@onready var player_healthbar = $player_healthbar
@onready var enemy_healthbar = $enemy_healthbar
@onready var gem_sprite = $gem_sprite
@onready var exp_timer = $exp_timer

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

var is_duel: bool = false
var player_escape_attempts: int = 0
var choosing_item_target: bool = false

func _ready():
    item_chooser.updated_cursor.connect(item_warning.close)
    party_menu.clear_warning.connect(party_warning.close)

    var species_cat = load("res://familiar/species/catsith.tres")
    var spell_scratch = load("res://familiar/spells/scratch.tres")
    var spell_growl = load("res://familiar/spells/growl.tres")
    var item_gem = load("res://familiar/items/gem.tres")
    var item_potion = load("res://familiar/items/potion.tres")

    player_party.familiars.append(Familiar.new(species_cat, 5))
    player_party.familiars[0].nickname = "Jiji"
    player_party.familiars[0].spells.append(spell_scratch)
    player_party.familiars[0].spells.append(spell_growl)
    player_party.familiars.append(Familiar.new(species_cat, 3))
    player_party.familiars[1].nickname = "Meowth"
    player_party.familiars[1].spells.append(spell_scratch)
    player_party.familiars[1].spells.append(spell_growl)
    enemy_party.familiars.append(Familiar.new(species_cat, 5))
    enemy_party.familiars[0].spells.append(spell_scratch)
    # enemy_party.familiars[0].spells.append(spell_growl)

    player_party.add_item(item_gem, 5)
    player_party.add_item(item_potion, 10)

    battle_start()

func battle_start():
    player_party.before_battle()
    enemy_party.before_battle()

    dialog.clear()
    dialog.visible = true
    await animator.animate_enter()
    enemy_healthbar.open()
    dialog.open("A wild " + enemy_party.familiars[0].get_display_name() + "\nappeared!")
    await dialog.finished
    dialog.clear()

    await animator.animate_player_exit()
    await summon_familiar(ActionActor.PLAYER)
    dialog.clear()

    battle_actions.open()

func summon_familiar(who: ActionActor):
    var party = player_party if who == ActionActor.PLAYER else enemy_party
    var message = "You summon" if who == ActionActor.PLAYER else "Enemy summons"
    message += "\n" + party.familiars[0].get_display_name() + "!"

    dialog.open(message)
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
                dialog.open("There's no running\nfrom a duel!")
                await dialog.finished
                dialog.clear()
                battle_actions.open(true)
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
            battle_actions.open()
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
            battle_actions.open(true)
        elif not player_party.familiars[party_menu.choice].is_living():
            party_warning.open(player_party.familiars[party_menu.choice].get_display_name() + " is out\nof energy!")
            party_menu.is_finished = false
        elif party_menu.choice == 0:
            party_warning.open(player_party.familiars[0].get_display_name() + " is already\nfighting!")
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
            item_warning.close()
            item_chooser.close()
            battle_actions.open(true)
        else:
            # warn player they can't use gem
            if chosen_item.type == Item.ItemType.GEM and is_duel:
                item_warning.open("Can't use that\nin a duel!")
                item_chooser.finished = false
            # use gem
            elif chosen_item.type == Item.ItemType.GEM:
                item_chooser.close()
                item_warning.close()
                player_party.remove_item(chosen_item)
                do_action({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.ITEM,
                    "item": chosen_item
                })
            elif chosen_item.type == Item.ItemType.HEALING:
                item_warning.close()
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
            party_warning.open("You can't heal a\ndefeated familiar!")
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
    elif player_party.familiars[0].get_agility() == enemy_party.familiars[0].get_agility():
        player_first = randi_range(0, 1) == 0
    else:
        player_first = player_party.familiars[0].get_agility() > enemy_party.familiars[0].get_agility()

    # do each turn
    var actions = [player_action, enemy_action] if player_first else [enemy_action, player_action]
    for action in actions:
        await do_action(action)

        # check if player familiar is dead
        if not player_party.familiars[0].is_living():
            dialog.open(player_party.familiars[0].get_display_name() + "\nwas defeated!")
            await animator.animate_faint(ActionActor.PLAYER)
            if not dialog.is_finished:
                await dialog.finished
            player_healthbar.close()
            dialog.clear()

            if player_party.is_defeated():
                dialog.open("All of your lads have\nbeen knocked out!")
                return
            elif not player_party.familiars[0].is_living():
                party_menu.open(false)
                await resume_round
        # check if enemy familiar is dead
        if not enemy_party.familiars[0].is_living():
            dialog.open("Enemy " + enemy_party.familiars[0].get_display_name() + "\nwas defeated!")
            await animator.animate_faint(ActionActor.ENEMY)
            if not dialog.is_finished:
                await dialog.finished
            enemy_healthbar.close()
            dialog.clear()

            if enemy_party.is_defeated():
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
                    if not player_party.familiars[i].is_living():
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
                                party_menu.announce_level_up(i)
                            if exp_each[i] > 0:
                                exp_finished = false
                return
            elif not enemy_party.familiars[0].is_living():
                return
    # end for action in actions

    # open action menu for player's next turn
    battle_actions.open()

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
        message += attacker.get_display_name() + "\nused " + action.spell.name + "!"
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
            miss_message += attacker.get_display_name() + "'s\nattack missed!"
            dialog.open(miss_message)
            await dialog.finished
            dialog.clear()

        if spell_hit:
            # Compute base damage
            var attacker_attack: float = attacker.get_strength() if action.spell.damage_type == Spell.DamageType.PHYSICAL else attacker.get_intellect()
            var base_damage: float = (((((2.0 * attacker.level) / 5.0) + 2.0) * action.spell.power * (attacker_attack / defender.get_defense())) / 50.0) + 2.0

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
            if crit_value <= crit_chance:
                crit_mod = 2.0

            var random_mod: float = randf_range(0.85, 1.0)
            var damage = int(base_damage * stab * type_mod * crit_mod * random_mod)

            defender.health = max(defender.health - damage, 0)

            await animator.animate_spell(action.actor, action.spell.animation)
            defender_healthbar.update()
            await animator.animate_hurt((action.actor + 1) % 2, type_mod)
            if crit_mod == 2.0:
                dialog.open("Critical hit!")
                await dialog.finished
                dialog.clear()
            if type_mod == 2.0:
                dialog.open("It's super\neffective!")
                await dialog.finished
                dialog.clear()
            if type_mod == 0.5:
                dialog.open("It's not very\neffective...")
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
                if (stat_mod > 0 and target_current_stage == 2) or (stat_mod < 0 and target_current_stage == -2):
                    continue

                var stat_verb = "rose" if stat_mod > 0 else "fell"
                condition_target[stat_name + "_stage"] = clamp(target_current_stage + stat_mod, -2, 2)
                condition_target_healthbar.refresh()
                dialog.open(condition_target_name + "'s\n" + stat_name.to_upper() + " " + stat_verb + "!")
                await dialog.finished
            if action.spell.condition != Condition.Type.NONE:
                if condition_target.condition != Condition.Type.NONE and action.spell.damage_type == Spell.DamageType.NONE:
                    dialog.open("But it failed!")
                    await dialog.finished
                if condition_target.condition == Condition.Type.NONE:
                    condition_target.condition = action.spell.condition
                    condition_target_healthbar.update()
                    dialog.open(condition_target_name + Condition.INFO[action.spell.condition].apply_message)
                    await animator.animate_spell(Condition.INFO[action.spell.condition].animation)
                    if not dialog.is_finished:
                        await dialog.finished
                    dialog.clear()
    # SWITCH
    elif action.type == ActionType.SWITCH:
        var attacker_party = player_party if action.actor == ActionActor.PLAYER else enemy_sprite

        await animator.animate_unsummon(action.actor)
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
        await enemy_sprite.animate_unsummon()
        await gem_sprite.animate_fall()
        await gem_sprite.animate_ticks(num_ticks)

        if catch_successful:
            gem_sprite.play("catch")

            dialog.open("Gotcha! " + familiar.get_display_name() + "\nwas caught!")
            await dialog.finished
        else:
            gem_sprite.visible = false
            await enemy_sprite.animate_summon(familiar.species.name)

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
    if familiar.condition == Condition.Type.BURN:
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
