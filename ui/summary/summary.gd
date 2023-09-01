extends NinePatchRect

@onready var player_party = get_node("/root/player_party")

@onready var name_label = $name_label
@onready var level_label = $name_label/level_label
@onready var species_label = $name_label/species_label
@onready var type_value = $name_label/type_label/type_value
@onready var type_icon = $name_label/type_label/type_icon
@onready var sign_label = $name_label/sign_label

@onready var health_amount = $health_cluster/health_amount
@onready var healthbar = $health_cluster/healthbar
@onready var status_icon = $health_cluster/status_icon
@onready var status_label = $health_cluster/status_label

@onready var stat_cluster = $stat_cluster
@onready var strength_value = $stat_cluster/strength_label/value
@onready var intellect_value = $stat_cluster/intellect_label/value
@onready var defense_value = $stat_cluster/defense_label/value
@onready var agility_value = $stat_cluster/agility_label/value
@onready var expbar = $stat_cluster/exp_cluster/expbar
@onready var exp_value = $stat_cluster/exp_cluster/exp_label/value
@onready var tnl_value = $stat_cluster/exp_cluster/tnl_label/value

@onready var sprite = $sprite_frame/sprite

var healthbar_max_width: int
var expbar_max_width: int

var familiar_index: int = 0

func _ready():
    var species_adder = load("res://familiar/species/adder.tres")
    var species_cat = load("res://familiar/species/catsith.tres")
    var spell_scratch = load("res://familiar/spells/scratch.tres")
    var spell_growl = load("res://familiar/spells/growl.tres")

    player_party.familiars.append(Familiar.new(species_adder, 5))
    player_party.familiars[0].nickname = "Monty"
    player_party.familiars[0].condition = Condition.Type.POISONED
    player_party.familiars.append(Familiar.new(species_cat, 5))
    player_party.familiars[1].nickname = "Jiji"
    player_party.familiars[1].spells.append(spell_scratch)
    player_party.familiars[1].spells.append(spell_growl)

    healthbar_max_width = healthbar.size.x
    expbar_max_width = expbar.size.x
    visible = false

    open(0)

func open(index: int):
    familiar_index = index
    var familiar = player_party.familiars[familiar_index]

    name_label.text = familiar.get_display_name()
    level_label.text = "Lv" + str(familiar.level)
    species_label.text = familiar.species.name
    type_value.text = Types.Type.keys()[familiar.species.type]
    type_icon.frame = familiar.species.type as int
    sign_label.text = "SIGN: " + Familiar.Zodiac.keys()[familiar.zodiac]

    health_amount.text = str(familiar.health) + "/" + str(familiar.max_health)
    healthbar.size.x = int((float(familiar.health) / float(familiar.max_health)) * healthbar_max_width)

    if familiar.condition == Condition.Type.NONE:
        status_icon.visible = false
        status_label.visible = false
    else:
        status_icon.frame = familiar.condition as int
        for condition_name in Condition.Type.keys():
            if Condition.Type[condition_name] == familiar.condition:
                status_label.text = condition_name
                break
        status_icon.visible = true
        status_label.visible = true

    stat_cluster.visible = true
    strength_value.text = str(familiar.strength)
    intellect_value.text = str(familiar.intellect)
    defense_value.text = str(familiar.defense)
    agility_value.text = str(familiar.agility)

    expbar.size.x = int(expbar_max_width * (familiar.get_experience_toward_next_level() / float(familiar.get_experience_for_next_level())))
    exp_value.text = str(familiar.experience)
    tnl_value.text = str(familiar.get_experience_to_next_level())

    sprite.texture = load("res://battle/sprites/front/" + familiar.species.name.to_lower().replace(" ", "-") + ".png")

    visible = true
