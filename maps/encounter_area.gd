extends Area2D

onready var director = get_node("/root/Director")
onready var random = get_node("/root/Random")
onready var player = get_parent().get_node("player")

export var encounter_rate: float = 0.05
export(Array, Resource) var encounters
export(Array, float) var rates

func _ready():
    player.connect("took_step", self, "_on_player_took_step")

func _on_player_took_step():
    if overlaps_area(player):
        var encounter_value = random.rng.randf_range(0.0, 1.0)
        if encounter_value <= encounter_rate:
            player.input_direction = Vector2.ZERO

            var species_value = random.rng.randf_range(0.0, 1.0)
            var species_rate = 0.0
            var species_index = 0
            for i in range(0, encounters.size()):
                species_rate += rates[i]
                if species_value <= species_rate:
                    species_index = i
                    break

            var level = random.rng.randi_range(encounters[species_index].low_level, encounters[species_index].high_level)
            var familiar = Familiar.new(encounters[species_index].species, level)
            for i in range(0, encounters[species_index].spells.size()):
                familiar.spells[i] = encounters[species_index].spells[i]
                familiar.spells_known.append(familiar.spells[i])

            director.start_battle({
                "type": "wild",
                "familiar": familiar
            })