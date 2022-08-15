extends Reference
class_name Familiar

const MAX_LEVEL = 100

var species: Species
var nickname: String = ""
var experience: int = 0
var level: int = 1

var health: int
var max_health: int

var mana: int 
var max_mana: int

var attack: int
var defense: int
var speed: int

var spells = []
var conditions = []

func _init(as_species: Species, at_level: int):
    species = as_species
    experience = 0
    set_level(at_level)
    health = max_health
    mana = max_mana

func get_name() -> String:
    if nickname == "":
        return species.name.to_upper()
    else:
        return nickname

func is_living() -> bool:
    return health > 0

func get_exp_yield() -> int:
    return int((species.base_exp_yield * level) / 7.0)

func set_level(value: int):
    experience = get_experience_at_level(value)
    level = value
    update_stats()

func get_attack() -> int:
    for condition in conditions:
        if condition.type == Conditions.Condition.ATTACK_UP:
            return int(ceil(attack * 2.0))
        elif condition.type == Conditions.Condition.ATTACK_DOWN:
            return int(ceil(attack / 2.0))
    return attack

func get_defense() -> int:
    for condition in conditions:
        if condition.type == Conditions.Condition.DEFENSE_UP:
            return int(ceil(defense * 2.0))
        elif condition.type == Conditions.Condition.DEFENSE_DOWN:
            return int(ceil(defense / 2.0))
    return defense

func get_speed() -> int:
    for condition in conditions:
        if condition.type == Conditions.Condition.SPEED_UP:
            return int(ceil(speed * 2.0))
        elif condition.type == Conditions.Condition.SPEED_DOWN:
            return int(ceil(speed / 2.0))
    return speed

func update_stats():
    max_health = int((species.base_health * 2.0 * level) / 100) + level + 10
    max_mana = int((species.base_mana * 1.25 * level) / 100) + 5
    attack = int((species.base_attack * 2.0 * level) / 100) + 5
    defense = int((species.base_defense * 2.0 * level) / 100) + 5
    speed = int((species.base_speed * 2.0 * level) / 100) + 5

func get_experience_at_level(value: int) -> int:
    return int(pow((value), 3))

func get_current_experience() -> int:
    if level == 1:
        return experience
    else:
        return experience - get_experience_at_level(level)

func get_experience_tnl() -> int:
    return get_experience_at_level(level + 1) - get_experience_at_level(level)

func get_experience_left_for_level() -> int:
    return get_experience_tnl() - get_current_experience()

func change_health(amount: int):
    health += amount
    health = int(clamp(health, 0, max_health))

func change_mana(amount: int):
    mana += amount
    mana = int(clamp(mana, 0, max_mana))

func change_exp(amount: int):
    var exp_left = amount
    while exp_left != 0:
        if exp_left >= get_experience_left_for_level():
            experience += get_experience_left_for_level()
            exp_left -= get_experience_left_for_level()
            level += 1
        else:
            experience += exp_left
            exp_left = 0

func do_post_battle_stuff():
    if is_living():
        mana = max_mana
    clear_temp_conditions()

func clear_temp_conditions():
    for condition in conditions:
        if Conditions.INFO[condition.type].duration == Conditions.DURATION_INDEFINITE:
            continue
        conditions.erase(condition)

func add_condition(condition_type) -> String:
    for condition in conditions:
        # If familiar has condition already, do nothing
        if condition.type == condition_type:
            return Conditions.INFO[condition.type].noeffect_message
        # If familiar has this condition's opposite, don't add the condition but cancel out the opposite
        elif Conditions.INFO[condition.type].opposite == condition_type:
            conditions.erase(condition)
            return Conditions.INFO[condition.type].remove_message
    # Otherwise add the condition
    conditions.append({
        "type": condition_type,
        "ttl": Conditions.INFO[condition_type].duration
    })
    return Conditions.INFO[condition_type].apply_message

func remove_condition(condition_type) -> String:
    for condition in conditions:
        if condition.type == condition_type:
            conditions.erase(condition)
            return Conditions.INFO[condition_type].remove_message
    return ""
