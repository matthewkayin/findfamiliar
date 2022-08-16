extends Node

const MAX_PARTY_SIZE = 6

var familiars = []
var reserves = []

func _ready():
    familiars.append(Familiar.new(load("res://data/species/raven.tres"), 5))
    familiars.append(Familiar.new(load("res://data/species/raven.tres"), 5))
    familiars[0].nickname = "Poe"
    var firebolt = load("res://data/spells/fire_bolt.tres")
    var witchbolt = load("res://data/spells/witch_bolt.tres")
    var growl = load("res://data/spells/growl.tres")
    var shock = load("res://data/spells/shock.tres")
    familiars[0].spells_known = [firebolt, witchbolt]
    familiars[0].spells[0] = firebolt
    familiars[0].spells[2] = witchbolt
    familiars[1].spells[0] = firebolt
    familiars[1].spells[1] = witchbolt
    familiars[0].experience += familiars[0].get_experience_tnl() - 42
    familiars[1].experience += familiars[0].get_experience_tnl() - 10

func add_familiar(familiar: Familiar):
    if familiars.size() == MAX_PARTY_SIZE:
        reserves.append(familiar)
    else:
        familiars.append(familiar)

func swap_familiars(a: int, b: int):
    if a == b:
        return
    var temp = familiars[a]
    familiars[a] = familiars[b]
    familiars[b] = temp

func living_familiar_count() -> int:
    var count = 0
    for familiar in familiars:
        if familiar.is_living():
            count += 1
    return count