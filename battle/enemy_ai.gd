extends Node
class_name EnemyAI

enum Difficulty {
    WILD,
    WITCH
}

var player_party
var enemy_party 
var difficulty: Difficulty

func choose_action():
    if difficulty == Difficulty.WILD:
        var spell = enemy_party.familiars[0].spells[randi_range(0, enemy_party.familiars[0].spells.size() - 1)]
        return {
            "actor": Battle.ActionActor.ENEMY,
            "type": Battle.ActionType.SPELL,
            "spell": spell
        }

    var possible_actions = []
    for spell in enemy_party.familiars[0].spells:
        var action = {
            "actor": Battle.ActionActor.ENEMY,
            "type": Battle.ActionType.SPELL,
            "spell": spell
        }
        var score = score_spell(spell)
        possible_actions.append({
            "action": action,
            "score": score
        })

    possible_actions.sort_custom(func(a, b): return a.score > b.score)
    # for action in possible_actions:
        # print(action.action.spell.name + ":" + str(action.score))
    # print("--")
    return possible_actions[0].action

func get_strongest_spell(attacker: Familiar, defender: Familiar):
    var strongest = attacker.spells[0]
    var strongest_damage = Battle.calculate_damage(attacker, defender, strongest).randomless_damage
    for i in range(1, attacker.spells.size()):
        var spell_damage = Battle.calculate_damage(attacker, defender, strongest).randomless_damage
        if spell_damage > strongest_damage:
            strongest = attacker.spells[i]
            strongest_damage = spell_damage
    return {
        "spell": strongest,
        "damage": strongest_damage
    }

func player_can_1hko():
    var result = get_strongest_spell(player_party.familiars[0], enemy_party.familiars[0])
    return result.damage >= enemy_party.familiars[0].health

func player_can_2hko():
    var result = get_strongest_spell(player_party.familiars[0], enemy_party.familiars[0])
    return int(result.damage * 2.0) >= enemy_party.familiars[0].health

func enemy_can_1hko():
    var result = get_strongest_spell(enemy_party.familiars[0], player_party.familiars[0])
    return result.damage >= player_party.familiars[0].health

func enemy_can_2hko():
    var result = get_strongest_spell(enemy_party.familiars[0], player_party.familiars[0])
    return int(result.damage * 2.0) >= player_party.familiars[0].health

func is_disadvantaged(defender: Familiar, attacker: Familiar):
    return Types.EFFECTIVENESS[attacker.species.type].has(defender.species.type) and Types.EFFECTIVENESS[attacker.species.type][defender.species.type] == 2.0

func is_advantaged(attacker: Familiar, defender: Familiar):
    return is_disadvantaged(defender, attacker)

func predict_player_action():
    var player_can_kill = player_party.familiars[0].get_speed() > enemy_party.familiars[0].get_speed() and player_can_1hko()
    var player_is_disadvantaged = is_disadvantaged(player_party.familiars[0], enemy_party.familiars[0])
    var player_is_advantaged = is_advantaged(player_party.familiars[0], enemy_party.familiars[0])
    var player_has_advantaged_reserve = false
    for i in range(1, player_party.familiars.size()):
        if is_advantaged(player_party.familiars[i], enemy_party.familiars[0]):
            player_has_advantaged_reserve = true
            break

    var player_will_switch = false
    if player_is_disadvantaged and not player_is_advantaged and not player_can_kill:
        player_will_switch = true
    elif not player_is_advantaged and player_has_advantaged_reserve and randf_range(0.0, 1.0) <= 0.75:
        player_will_switch = true
    elif enemy_can_1hko() and player_party.get_living_familiar_count() > 1 and randf_range(0.0, 1.0) <= 0.5:
        player_will_switch = true

    if player_will_switch:
        return {
            "action": Battle.ActionType.SWITCH
        }

    var result = get_strongest_spell(player_party.familiars[0], enemy_party.familiars[0])
    return {
        "action": Battle.ActionType.SPELL,
        "spell": result.spell
    }

func score_spell(spell: Spell):
    var damage_score: float = Battle.calculate_damage(enemy_party.familiars[0], player_party.familiars[0], spell).randomless_damage / float(player_party.familiars[0].health)
    var stat_mod_score: float = 0.0
    if not player_can_1hko() and not enemy_can_2hko():
        for stat_name in Familiar.STAT_NAMES:
            var spell_stat_mod = spell[stat_name + "_mod"]
            if stat_name == "agility" and enemy_party.familiars[0].get_agility() > player_party.familiars[0].get_agility():
                continue
            if spell.condition_target == Spell.ConditionTarget.SELF and enemy_party.familiars[0][stat_name + "_stage"] >= spell_stat_mod * 2:
                continue
            if spell.condition_target == Spell.ConditionTarget.OPPONENT and player_party.familiars[0][stat_name + "_stage"] <= spell_stat_mod * 2:
                continue
            stat_mod_score += 0.2 * abs(spell_stat_mod)
    var condition_score: float = 0.0
    if spell.condition != Condition.Type.NONE and spell.condition_target == Spell.ConditionTarget.OPPONENT and player_party.familiars[0].condition == Condition.Type.NONE and not enemy_can_2hko():
        condition_score = spell.condition_accuracy / 100.0

    return damage_score + stat_mod_score + condition_score
