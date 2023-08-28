extends Node
class_name Familiar

const STAT_NAMES = ["strength", "intellect", "defense", "agility"]

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
var condition: Condition.Type = Condition.Type.NONE

# in battle variables
var strength_stage: int = 0
var intellect_stage: int = 0
var defense_stage: int = 0
var agility_stage: int = 0
var has_participated: bool = false

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

func get_stat_mod(stage: int) -> float:
    if stage > 0:
        return (2.0 + (stage * 2)) / 2.0
    if stage < 0:
        return 2.0 / (2.0 + (abs(stage) * 2))
    return 1.0

func get_strength() -> int:
    print(get_display_name(), " str ", strength, " stage ", strength_stage, " mod ", get_stat_mod(strength_stage), " result ", int(strength * get_stat_mod(strength_stage)))
    return int(strength * get_stat_mod(strength_stage))

func get_intellect() -> int:
    return int(intellect * get_stat_mod(intellect_stage))

func get_defense() -> int:
    return int(defense * get_stat_mod(defense_stage))

func get_agility() -> int:
    return int(agility * get_stat_mod(agility_stage))

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