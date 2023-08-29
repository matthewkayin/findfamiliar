extends Node
class_name Familiar

const STAT_NAMES = ["strength", "intellect", "defense", "agility"]

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
    zodiac = randi_range(0, 11) as Zodiac
    set_level(at_level)
    health = max_health

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

func calculate_stat(base: int, growth_zodiacs: Array[Zodiac], stunt_zodiacs: Array[Zodiac]) -> int:
    var growth_multiplier = 1.0
    if growth_zodiacs.has(zodiac):
        growth_multiplier = 1.1
    elif stunt_zodiacs.has(zodiac):
        growth_multiplier = 0.9
    return int((((base * 2.0 * level) / 100) + 5) * growth_multiplier)

func update_stats():
    max_health = int((species.base_health * 2.0 * level) / 100) + level + 10

    strength = calculate_stat(species.base_strength, [Zodiac.VIRGO, Zodiac.LEO, Zodiac.ARIES], [Zodiac.PISCES, Zodiac.AQUARIUS, Zodiac.LIBRA])
    intellect = calculate_stat(species.base_intellect, [Zodiac.PISCES, Zodiac.SCORPIO, Zodiac.CANCER], [Zodiac.VIRGO, Zodiac.TAURUS, Zodiac.CAPRICORN])
    defense = calculate_stat(species.base_defense, [Zodiac.AQUARIUS, Zodiac.TAURUS, Zodiac.SAGITTARIUS], [Zodiac.LEO, Zodiac.SCORPIO, Zodiac.GEMINI])
    agility = calculate_stat(species.base_agility, [Zodiac.LIBRA, Zodiac.CAPRICORN, Zodiac.GEMINI], [Zodiac.ARIES, Zodiac.CANCER, Zodiac.SAGITTARIUS])