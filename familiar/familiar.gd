extends Node
class_name Familiar

const STAT_NAMES = ["strength", "intellect", "defense", "agility", "luck"]

enum Zodiac {
    ARIES = 0,
    TAURUS = 1,
    GEMINI = 2,
    CANCER = 3,
    LEO = 4,
    VIRGO = 5,
    LIBRA = 6,
    SCORPIO = 7,
    SAGITTARIUS = 8,
    CAPRICORN = 9,
    AQUARIUS = 10,
    PISCES = 11
}

var species: Species
var nickname: String = ""
var zodiac: Zodiac = Zodiac.ARIES
var experience: int = 0
var level: int = 5

# stats
var health: int = 20
var max_health: int = 20
var strength: int = 5
var strength_dv: int = 0
var intellect: int = 5
var intellect_dv: int = 0
var defense: int = 5
var defense_dv: int = 0
var agility: int = 5
var agility_dv: int = 0

# spells
var spells: Array[Spell] = []

# conditions
var condition: Condition.Type = Condition.Type.NONE

# in battle variables
var strength_stage: int = 0
var intellect_stage: int = 0
var defense_stage: int = 0
var agility_stage: int = 0
var luck_stage: int = 0
var has_participated: bool = false

func _init(as_species: Species, at_level: int):
    species = as_species

    zodiac = randi_range(0, 11) as Zodiac
    strength_dv = randi_range(0, 15)
    intellect_dv = randi_range(0, 15)
    defense_dv = randi_range(0, 15)
    agility_dv = randi_range(0, 15)

    set_level(at_level)
    health = max_health

    for i in range(0, species.learn_spells.size()):
        var learn_spell = species.learn_spells[species.learn_spells.size() - 1 - i]
        if learn_spell.level > level:
            continue
        spells.insert(0, learn_spell.spell)
        if spells.size() == 4:
            break

func get_display_name() -> String:
    if nickname == "":
        return species.name.to_upper()
    else:
        return nickname

func is_living() -> bool:
    return health > 0

func clear_stat_mods():
    strength_stage = 0
    intellect_stage = 0
    defense_stage = 0
    agility_stage = 0

func get_stat_mod(stage: int) -> float:
    if stage > 0:
        return (2.0 + stage) / 2.0
    if stage < 0:
        return 2.0 / (2.0 + abs(stage))
    return 1.0

func get_strength() -> int:
    var burn_mod = 1.0
    if condition == Condition.Type.BURNED:
        burn_mod = 0.7
    return int(strength * get_stat_mod(strength_stage) * burn_mod)

func get_intellect() -> int:
    return int(intellect * get_stat_mod(intellect_stage))

func get_defense() -> int:
    return int(defense * get_stat_mod(defense_stage))

func get_agility() -> int:
    return int(agility * get_stat_mod(agility_stage))

func get_luck() -> float:
    return get_stat_mod(luck_stage)

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

func calculate_stat(base: int, base_dv: int):
    return int((((base + base_dv) * 2.0 * level) / 100) + 5)

func update_stats():
    max_health = int((species.base_health * 2.0 * level) / 100) + level + 10

    strength = calculate_stat(species.base_strength, strength_dv)
    intellect = calculate_stat(species.base_intellect, intellect_dv)
    defense = calculate_stat(species.base_defense, defense_dv)
    agility = calculate_stat(species.base_agility, agility_dv)