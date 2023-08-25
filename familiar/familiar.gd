extends Node
class_name Familiar

var species: Species
var nickname: String = ""
var experience: int = 0
var level: int = 5

# stats
var health: int = 20
var max_health: int = 20
var strength: int = 5
var intellect: int = 5
var defense: int = 5
var agility: int = 5

# spells
var spells: Array[Spell] = []

# conditions
var conditions: Array[Dictionary] = []

# in battle flags
var has_attacked: bool = false
var has_switched: bool = false
var has_used_item: bool = false

func _init(as_species: Species, at_level: int):
    species = as_species
    experience = 0
    set_level(at_level)
    health = max_health

func get_display_name() -> String:
    if nickname == "":
        return species.name.to_upper()
    else:
        return nickname

func is_living() -> bool:
    return health > 0

func get_strength() -> int:
    var mod = 1.0
    if has_condition(Condition.Type.STR_UP):
        mod = 2.0
    elif has_condition(Condition.Type.STR_DOWN):
        mod = 0.5
    return strength * mod

func get_intellect() -> int:
    var mod = 1.0
    if has_condition(Condition.Type.INT_UP):
        mod = 2.0
    elif has_condition(Condition.Type.INT_DOWN):
        mod = 0.5
    return intellect * mod

func get_defense() -> int:
    var mod = 1.0
    if has_condition(Condition.Type.DEF_UP):
        mod = 2.0
    elif has_condition(Condition.Type.DEF_DOWN):
        mod = 0.5
    return defense * mod

func get_agility() -> int:
    var mod = 1.0
    if has_condition(Condition.Type.AGI_UP):
        mod = 2.0
    elif has_condition(Condition.Type.AGI_DOWN):
        mod = 0.5
    return agility * mod

# level, stats, and experience

func set_level(value: int):
    experience = get_experience_at_level(value)
    level = value
    update_stats()

func give_exp(value: int) -> bool:
    experience += value
    var leveled_up = false
    while experience >= get_experience_at_level(level + 1):
        level += 1
        leveled_up = true
    update_stats()

    return leveled_up

func get_experience_at_level(value: int) -> int:
    return int(pow(value, 3))

func get_experience_for_next_level() -> int:
    return get_experience_at_level(level + 1) - get_experience_at_level(level)

func get_experience_toward_next_level() -> int:
    return experience - get_experience_at_level(level)
    
func get_experience_to_next_level() -> int:
    return get_experience_for_next_level() - get_experience_toward_next_level()

func update_stats():
    max_health = int((species.base_health * 2.0 * level) / 100) + level + 10
    strength = int((species.base_strength * 2.0 * level) / 100) + 5
    intellect = int((species.base_intellect * 2.0 * level) / 100) + 5
    defense = int((species.base_defense * 2.0 * level) / 100) + 5
    agility = int((species.base_agility * 2.0 * level) / 100) + 5

# conditions

func has_condition(type: Condition.Type):
    for condition in conditions:
        if condition.type == type:
            return true
    return false

func add_condition(type: Condition.Type) -> bool:
    var remove_indices = []
    for i in range(0, conditions.size()):
        if conditions[i].type == type:
            conditions[i].ttl = Condition.INFO[type].ttl
            return false
        if Condition.INFO[type].opposites.has(conditions[i].type):
            remove_indices.append(i)
    for index in remove_indices:
        conditions.remove_at(index)

    if remove_indices.is_empty() or Condition.INFO[type].apply_anyway:
        conditions.append({
            "type": type,
            "ttl": Condition.INFO[type].ttl
        })
    return true

func tick_conditions() -> Array[int]:
    var remove_indices: Array[int] = []
    for i in range(0, conditions.size()):
        if conditions[i].ttl == Condition.TTL_INDEFINITE:
            continue
        if conditions[i].ttl == 0:
            remove_indices.append(i)
        else:
            conditions[i].ttl -= 1
    return remove_indices
