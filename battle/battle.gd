extends Node2D

@onready var dialog = $dialog
@onready var battle_actions = $battle_actions
@onready var spell_chooser = $spell_chooser
@onready var spell_info = $spell_info
@onready var spell_warning = $spell_warning
@onready var party_menu = $party_menu
@onready var party_warning = $party_warning
@onready var item_chooser = $item_chooser
@onready var item_warning = $item_warning
@onready var turn_popup = $turn_popup
@onready var player_sprite = $player_sprite
@onready var enemy_sprite = $enemy_sprite
@onready var player_healthbar = $player_healthbar
@onready var enemy_healthbar = $enemy_healthbar
@onready var gem_sprite = $gem_sprite
@onready var exp_timer = $exp_timer

@onready var species_cat = preload("res://familiar/species/catsith.tres")
@onready var spell_scratch = preload("res://familiar/spells/scratch.tres")
@onready var spell_growl = preload("res://familiar/spells/growl.tres")
@onready var item_gem = preload("res://familiar/items/gem.tres")
@onready var item_potion = preload("res://familiar/items/potion.tres")
@onready var item_potion2 = preload("res://familiar/items/potion2.tres")
@onready var item_potion3 = preload("res://familiar/items/potion3.tres")
@onready var item_potion4 = preload("res://familiar/items/potion4.tres")

enum ActionActor {
    PLAYER,
    ENEMY
}

enum ActionType {
    SPELL,
    SWITCH,
    ITEM,
    END,
    RUN,
    REPLACE_SWITCH
}

var player_party = Party.new()
var enemy_party = Party.new()
var choosing_item_target = false
var current_turn = ActionActor.PLAYER
var player_escape_attempts = 0
var is_witch_battle = true

func _ready():
    spell_chooser.updated_cursor.connect(_on_move_spell_cursor)
    item_chooser.updated_cursor.connect(_on_move_item_cursor)
    party_menu.clear_warning.connect(_on_party_menu_clear_warning)

    battle_start()

func _on_move_spell_cursor():
    spell_info.open(player_party.familiars[0].spells[spell_chooser.cursor_index.y])
    spell_warning.close()

func _on_move_item_cursor():
    item_warning.close()

func _on_party_menu_clear_warning():
    party_warning.close()

func battle_start():
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

    player_party.before_battle()
    enemy_party.before_battle()

    player_healthbar.party = player_party
    enemy_healthbar.party = enemy_party
    party_menu.party = player_party

    dialog.clear()
    dialog.visible = true
    player_sprite.animate_enter("player")
    await enemy_sprite.animate_enter(enemy_party.familiars[0].species.name)
    enemy_healthbar.open()
    dialog.open("A wild " + enemy_party.familiars[0].get_display_name() + "\nappeared!")
    await dialog.finished
    dialog.clear()

    await player_sprite.animate_exit()
    await summon_familiar(true)
    var delay_tween = get_tree().create_tween()
    delay_tween.tween_interval(0.25)
    await delay_tween.finished
    begin_player_turn(true)

func summon_familiar(player: bool):
    var familiar = player_party.familiars[0] if player else enemy_party.familiars[0]
    var sprite = player_sprite if player else enemy_sprite
    var healthbar = player_healthbar if player else enemy_healthbar

    await sprite.animate_summon(familiar.species.name)
    healthbar.open()

func do_action(action):
    # SPELL
    if action.type == ActionType.SPELL:
        # setup attacker and defender
        var attacker: Familiar = player_party.familiars[0] if action.actor == ActionActor.PLAYER else enemy_party.familiars[0]
        var defender: Familiar = enemy_party.familiars[0] if action.actor == ActionActor.PLAYER else player_party.familiars[0]
        var attacker_sprite = player_sprite if action.actor == ActionActor.PLAYER else enemy_sprite
        var defender_sprite = enemy_sprite if action.actor == ActionActor.PLAYER else player_sprite
        var attacker_healthbar = player_healthbar if action.actor == ActionActor.PLAYER else enemy_healthbar
        var defender_healthbar = enemy_healthbar if action.actor == ActionActor.PLAYER else player_healthbar
        var attacker_party: Party = player_party if action.actor == ActionActor.PLAYER else enemy_party

        # Remove mana
        attacker_party.mana -= action.spell.cost
        attacker_healthbar.update()

        # display spell message
        var message = ""
        if action.actor == ActionActor.ENEMY:
            message += "Enemy "
        message += attacker.get_display_name() + "\nused " + action.spell.name + "!"
        dialog.open(message)
        await dialog.finished
        dialog.clear()

        # animate spell
        await attacker_sprite.animate_attack()

        # check if move hits or misses
        var spell_hit: bool = false
        if action.spell.damage_type != Spell.DamageType.NONE:
            var accuracy_dc: int = action.spell.accuracy + (float(attacker.get_agility() - defender.get_agility()) / 1.5)
            spell_hit = randi_range(0, 100) <= accuracy_dc
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

            await defender_sprite.animate_spell(action.spell.animation)
            defender_healthbar.update()
            defender_sprite.animate_hurt(type_mod)
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

        # else if not spell hit
        elif action.spell.damage_type != Spell.DamageType.NONE:
            var miss_message = ""
            if action.actor == ActionActor.ENEMY:
                miss_message += "Enemy "
            miss_message += attacker.get_display_name() + "'s\nattack missed!"
            dialog.open(miss_message)
            await dialog.finished
            dialog.clear()

        # determine if condition hit
        var condition_hit: bool = false
        var condition_dc: int = action.spell.condition_accuracy
        if defender.is_living() and action.spell.condition_target == Condition.Target.OPPONENT:
            condition_dc += int(float(attacker.get_intellect() - defender.get_intellect()) / 1.5)
            condition_hit = randi_range(0, 100) <= condition_dc
        elif action.spell.condition_target == Condition.Target.SELF or action.spell.condition_target == Condition.Target.PARTY:
            condition_hit = true

        # handle spell conditions
        if condition_hit:
            for condition in action.spell.conditions:
                # apply condition
                var use_apply_message: bool = false
                if action.spell.condition_target == Condition.Target.SELF:
                    use_apply_message = attacker.add_condition(condition)
                elif action.spell.condition_target == Condition.Target.PARTY:
                    for familiar in attacker_party.familiars:
                        familiar.add_condition(condition)
                    use_apply_message = true
                elif action.spell.condition_target == Condition.Target.OPPONENT:
                    use_apply_message = defender.add_condition(condition)

                # display condition message
                # set condition message name
                var condition_message = ""
                if action.spell.condition_target == Condition.Target.PARTY:
                    condition_message = "Your party" if action.actor == ActionActor.PLAYER else "Enemy party"
                elif action.spell.condition_target == Condition.Target.SELF:
                    if action.actor == ActionActor.ENEMY:
                        condition_message += "Enemy "
                    condition_message = attacker.get_display_name()
                elif action.spell.condition_target == Condition.Target.OPPONENT:
                    if action.actor == ActionActor.PLAYER:
                        condition_message += "Enemy "
                    condition_message = defender.get_display_name()
                # set condition message content
                if use_apply_message: 
                    condition_message += Condition.INFO[condition].apply_message
                elif action.spell.damage_type == Spell.DamageType.NONE:
                    condition_message += Condition.INFO[condition].reapply_message
                else:
                    condition_message = ""
                # open dialog box
                if condition_message != "":
                    dialog.open(condition_message)
                    attacker_healthbar.refresh()
                    defender_healthbar.refresh()
                    await dialog.finished
                    dialog.clear()
        # if not condition hit
        else:
            if action.spell.damage_type == Spell.DamageType.NONE:
                dialog.open("But it failed!")
                await dialog.finished
                dialog.clear()

        # update battle flag
        attacker.has_attacked = true
    # SWITCH
    elif action.type == ActionType.SWITCH:
        var attacker_sprite = player_sprite if action.actor == ActionActor.PLAYER else enemy_sprite
        var attacker_party = player_party if action.actor == ActionActor.PLAYER else enemy_sprite
        var attacker_healthbar = player_healthbar if action.actor == ActionActor.PLAYER else enemy_healthbar

        # Remove mana
        attacker_party.mana -= action.cost
        attacker_healthbar.update()

        await attacker_sprite.animate_unsummon()
        if attacker_healthbar.is_interpolating:
            await attacker_healthbar.finished
        attacker_healthbar.close()
        attacker_party.switch(0, action.index)
        var delay_tween = get_tree().create_tween()
        delay_tween.tween_interval(0.25)
        await delay_tween.finished
        await summon_familiar(action.actor == ActionActor.PLAYER)
    elif action.type == ActionType.REPLACE_SWITCH:
        var attacker_party = player_party if action.actor == ActionActor.PLAYER else enemy_sprite
        attacker_party.switch(0, action.index)
        await summon_familiar(action.actor == ActionActor.PLAYER)
    # TRY TO CATCH FAMILIAR
    elif action.type == ActionType.ITEM and action.item.type == Item.ItemType.GEM:
        player_party.mana -= 1
        player_healthbar.update()

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
            if player_party.mana > 0:
                player_party.mana -= 1
                player_healthbar.update()
            gem_sprite.visible = false
            await enemy_sprite.animate_summon(familiar.species.name)
    # RUN
    elif action.type == ActionType.RUN:
        player_escape_attempts += 1
        var escape_successful = player_party.familiars[0].get_agility() >= enemy_party.familiars[0].get_agility()
        if not escape_successful:
            var escape_odds = floor((player_party.familiars[0].get_agility() * 32.0) / (floor(enemy_party.familiars[0].get_agility() / 4.0) % 256)) + (30 * player_escape_attempts)
            escape_successful = escape_odds > 255 or randi_range(0, 255) < escape_odds
        
        escape_successful = false
        if escape_successful:
            dialog.open("Got away safely!")
            await dialog.finished
            dialog.clear()
        else:
            dialog.open("Can't escape!")
            player_party.mana = 0
            await player_healthbar.update()
            if not dialog.is_finished:
                await dialog.finished
            dialog.clear()

    # reset escape attempts
    if action.type != ActionType.RUN:
        player_escape_attempts = 0

    var actor_mana = player_party.mana if current_turn == ActionActor.PLAYER else enemy_party.mana
    var should_end_turn = actor_mana == 0 or action.type == ActionType.END

    # apply burn damage
    if should_end_turn:
        var familiar = player_party.familiars[0] if current_turn == ActionActor.PLAYER else enemy_party.familiars[0]
        if familiar.has_condition(Condition.Type.BURN):
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

    # check if player familiar is dead
    if not player_party.familiars[0].is_living():
        dialog.open(player_party.familiars[0].get_display_name() + "\nwas defeated!")
        await player_sprite.animate_faint()
        if not dialog.is_finished:
            await dialog.finished
        player_healthbar.close()
        dialog.clear()

        if player_party.is_defeated():
            dialog.open("All of your lads have\nbeen knocked out!")
            return
        elif not player_party.familiars[0].is_living():
            party_menu.open(true, false)
            return
    # check if enemy familiar is dead
    if not enemy_party.familiars[0].is_living():
        dialog.open("Enemy " + enemy_party.familiars[0].get_display_name() + "\nwas defeated!")
        await enemy_sprite.animate_faint()
        if not dialog.is_finished:
            await dialog.finished
        enemy_healthbar.close()
        dialog.clear()

        if enemy_party.is_defeated():
            # calculate exp gained
            var exp_yield: float = 0.0
            for i in range(0, enemy_party.familiars.size()):
                exp_yield += float(enemy_party.familiars[i].species.exp_yield * enemy_party.familiars[i].level) / 7.0
            if is_witch_battle:
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
            party_menu.open(true, false, true)

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

    # determine next state
    if current_turn == ActionActor.PLAYER:
        if should_end_turn:
            if player_party.mana == 0:
                player_party.burned_out = true
            begin_enemy_turn()
        else:
            battle_actions.open()
    elif current_turn == ActionActor.ENEMY:
        if should_end_turn:
            if enemy_party.mana == 0:
                enemy_party.burned_out = true
            begin_player_turn()
        else:
            enemy_turn()

func begin_player_turn(is_first_turn: bool = false):
    current_turn = ActionActor.PLAYER
    var skip_turn = player_party.burned_out
    player_party.before_turn()

    if is_first_turn:
        player_healthbar.update()
        battle_actions.open()
        return

    # announce turn
    if skip_turn:
        await turn_popup.open("Your turn!")
        await turn_popup.open("You're burned out!")
    else:
        turn_popup.open("Your turn!")
        await player_healthbar.update()

    # update conditions
    for familiar in player_party.familiars:
        var remove_indices = familiar.tick_conditions()
        for index in remove_indices:
            var message = familiar.get_display_name() + Condition.INFO[familiar.conditions[index].type].expire_message
            familiar.conditions.remove_at(index)
            player_healthbar.refresh()
            dialog.open(message)
            await dialog.finished
            dialog.clear()

    if skip_turn:
        begin_enemy_turn()
    else:
        battle_actions.open()

func begin_enemy_turn():
    current_turn = ActionActor.ENEMY
    var skip_turn = enemy_party.burned_out
    enemy_party.before_turn()

    # announce turn
    if skip_turn:
        await turn_popup.open("Enemy turn!")
        await turn_popup.open("Enemy's burned out!")
    else:
        turn_popup.open("Enemy turn!")
        await enemy_healthbar.update()

    # update conditions
    for familiar in enemy_party.familiars:
        var remove_indices = familiar.tick_conditions()
        for index in remove_indices:
            var message = "Enemy " + familiar.get_display_name() + Condition.INFO[familiar.conditions[index].type].expire_message
            familiar.conditions.remove_at(index)
            enemy_healthbar.refresh()
            dialog.open(message)
            await dialog.finished
            dialog.clear()

    if skip_turn:
        begin_player_turn()
    else:
        enemy_turn()

func _process(_delta):
    # handle party menu
    if choosing_item_target and party_menu.is_open() and party_menu.is_finished and not party_menu.is_interpolating:
        if party_menu.choice == -1:
            party_menu.close()
            item_chooser.open(player_party.items, true)
            choosing_item_target = false
        elif not player_party.familiars[party_menu.choice].is_living():
            party_warning.open("You can't heal a\ndefeated familiar!")
            party_menu.is_finished = false
        elif player_party.familiars[party_menu.choice].has_used_item:
            party_warning.open(player_party.familiars[party_menu.choice].get_display_name() + " already used\nan item this turn!")
            party_menu.is_finished = false
        else:
            # use the item
            player_party.mana -= 1
            player_party.use_item(item_chooser.choice, party_menu.choice)
            player_healthbar.update()

            # animate health change in party menu
            await party_menu.update_health()

            # close menus
            party_menu.close()
            item_chooser.close()
            player_healthbar.fast_update()
            choosing_item_target = false

            # determine next state
            if player_party.mana > 0:
                battle_actions.open()
            else:
                begin_enemy_turn()
    elif party_menu.is_open() and party_menu.is_finished and not party_menu.is_interpolating:
        if party_menu.choice == -1:
            party_menu.close()
            battle_actions.open(true)
        elif not player_party.familiars[party_menu.choice].is_living():
            party_warning.open(player_party.familiars[party_menu.choice].get_display_name() + " is out\nof energy!")
            party_menu.is_finished = false
        elif party_menu.choice == 0:
            party_warning.open(player_party.familiars[0].get_display_name() + " is already\nfighting!")
            party_menu.is_finished = false
        # checking if familiar is living here because if the player is switching
        # because their familiar just fainted, then we don't want to make this check
        elif player_party.familiars[0].is_living() and player_party.familiars[party_menu.choice].has_switched:
            party_warning.open(player_party.familiars[party_menu.choice].get_display_name() + " has already\nfought this turn!")
            party_menu.is_finished = false
        else:
            if player_party.familiars[0].is_living():
                var switch_cost = player_party.get_switch_cost(party_menu.choice)
                if player_party.mana < switch_cost:
                    party_warning.open("Not enough mana!")
                    party_menu.is_finished = false
                else:
                    party_menu.close()
                    do_action({
                        "actor": ActionActor.PLAYER,
                        "type": ActionType.SWITCH,
                        "index": party_menu.choice,
                        "cost": switch_cost
                    })
            # else if not familiars[0].is_living
            else:
                party_menu.close()
                do_action({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.REPLACE_SWITCH,
                    "index": party_menu.choice,
                })
    # handle chosen battle action
    elif battle_actions.is_open() and battle_actions.finished: 
        if battle_actions.choice == "SPELL":
            # display already attacked message
            if player_party.familiars[0].has_attacked:
                battle_actions.close()
                dialog.open(player_party.familiars[0].get_display_name() + " already\nattacked this turn!")
                await dialog.finished
                dialog.clear()
                battle_actions.open()
            elif player_party.familiars[0].has_condition(Condition.Type.SLEEP):
                battle_actions.close()
                dialog.open(player_party.familiars[0].get_display_name() + " is\nasleep! It can't\nmove!")
                await dialog.finished
                dialog.clear()
                battle_actions.open()
            # open spell chooser
            else:
                var spell_options: Array[String] = []
                for spell in player_party.familiars[0].spells:
                    spell_options.append(spell.name)
                spell_chooser.open_with(spell_options)
                battle_actions.close()
        elif battle_actions.choice == "SWITCH":
            if player_party.familiars[0].has_condition(Condition.Type.TRAPPED):
                battle_actions.close()
                dialog.open(player_party.familiars[0].get_display_name() + " is\ntrapped! It can't\nswitch!")
                await dialog.finished
                dialog.clear()
                battle_actions.open()
            else:
                battle_actions.close()
                party_menu.open()
        elif battle_actions.choice == "ITEM":
            battle_actions.close()
            item_chooser.open(player_party.items)
        elif battle_actions.choice == "END":
            do_action({
                "actor": ActionActor.PLAYER,
                "type": ActionType.END
            })
            battle_actions.close()
        elif battle_actions.choice == "RUN":
            if is_witch_battle:
                battle_actions.close()
                dialog.open("There's no running\nfrom a duel!")
                await dialog.finished
                dialog.clear()
                battle_actions.open(true)
            else:
                do_action({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.RUN
                })
                battle_actions.close()
    # handle chosen spell
    elif spell_chooser.is_open() and spell_chooser.finished:
        # return to battle actions
        if spell_chooser.choice == "":
            battle_actions.open()
            spell_chooser.close()
            spell_info.close()
            spell_warning.close()
        else:
            # get chosen spell
            var chosen_spell: Spell = null
            for spell in player_party.familiars[0].spells:
                if spell_chooser.choice == spell.name:
                    chosen_spell = spell
                    break
            # warn player if not enough mana
            if chosen_spell.cost > player_party.mana:
                spell_warning.open("Not enough mana!")
                spell_chooser.finished = false
            # use spell
            else:
                spell_chooser.close()
                spell_info.close()
                spell_warning.close()
                do_action({
                    "actor": ActionActor.PLAYER,
                    "type": ActionType.SPELL,
                    "spell": chosen_spell
                })
    # handle chosen item
    elif item_chooser.is_open() and item_chooser.finished:
        var chosen_item: Item = item_chooser.choice
        # return to battle actions
        if chosen_item == null:
            item_warning.close()
            item_chooser.close()
            battle_actions.open(true)
        else:
            # warn player if not enough mana
            if player_party.mana < 1:
                item_warning.open("Not enough\nmana!")
                item_chooser.finished = false
            # warn player they can't use gem
            elif chosen_item.type == Item.ItemType.GEM and is_witch_battle:
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
                party_menu.open(true)

func enemy_turn():
    if enemy_party.familiars[0].has_attacked:
        do_action({
            "actor": ActionActor.ENEMY,
            "type": ActionType.END,
        })
    else:
        var spell = enemy_party.familiars[0].spells[randi_range(0, enemy_party.familiars[0].spells.size() - 1)]
        do_action({
            "actor": ActionActor.ENEMY,
            "type": ActionType.SPELL,
            "spell": spell
        })
