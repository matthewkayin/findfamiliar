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