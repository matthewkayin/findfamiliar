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
    return strength

func get_intellect() -> int:
    return intellect

func get_defense() -> int:
    return defense

func get_agility() -> int:
    return agility

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
