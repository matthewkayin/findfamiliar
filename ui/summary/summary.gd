extends NinePatchRect

signal finished

@onready var player_party = get_node("/root/player_party")

@onready var page_label = $header/page_label
@onready var page_left_arrow = $header/page_left_arrow
@onready var page_right_arrow = $header/page_right_arrow

@onready var name_label = $name_label
@onready var level_label = $name_label/level_label
@onready var species_label = $name_label/species_label
@onready var type_value = $name_label/type_label/type_value
@onready var type_icon = $name_label/type_label/type_icon
@onready var sign_label = $name_label/sign_label

@onready var health_cluster = $health_cluster
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

@onready var sprite_frame = $sprite_frame
@onready var sprite = $sprite_frame/sprite

@onready var mini_header = $mini_header
@onready var mini_header_mini = $mini_header/mini
@onready var mini_name_label = $mini_header/name_label
@onready var mini_level_label = $mini_header/level_label
@onready var mini_type_value = $mini_header/type_label/type_value
@onready var mini_type_icon = $mini_header/type_label/type_icon

@onready var prepared_spells = $prepared_spells
@onready var known_spells = $known_spells

@onready var spell_desc = $spell_desc
@onready var spell_desc_label = $spell_desc/label

@onready var spell_info = $spell_info
@onready var spell_info_power_label = $spell_info/power_label
@onready var spell_info_accuracy_label = $spell_info/accuracy_label
@onready var spell_info_damage_type_icon = $spell_info/damage_type_icon
@onready var spell_info_damage_type_label = $spell_info/damage_type_icon/label
@onready var spell_info_spell_type_icon = $spell_info/spell_type_icon
@onready var spell_info_spell_type_label = $spell_info/spell_type_icon/label

enum Page {
    STATS,
    SPELLS
}

var healthbar_max_width: int
var expbar_max_width: int

var familiar_index: int = 0
var page: Page = Page.STATS

func _ready():
    healthbar_max_width = healthbar.size.x
    expbar_max_width = expbar.size.x
    visible = false

    prepared_spells.updated_cursor.connect(open_spell_info)
    known_spells.updated_cursor.connect(open_spell_info)

func close():
    visible = false

func open(index: int):
    open_stats_page(index)

func open_stats_page(index: int):
    familiar_index = index
    var familiar = player_party.familiars[familiar_index]

    page = Page.STATS
    page_label.text = "STATS"

    mini_header.visible = false
    prepared_spells.close()
    known_spells.close()
    spell_desc.visible = false
    spell_info.visible = false

    name_label.visible = true
    name_label.text = familiar.get_display_name()
    level_label.text = "Lv" + str(familiar.level)
    species_label.text = familiar.species.name
    type_value.text = Types.Type.keys()[familiar.species.type]
    type_icon.frame = familiar.species.type as int
    sign_label.text = "SIGN: " + Familiar.Zodiac.keys()[familiar.zodiac]

    health_cluster.visible = true
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

    sprite_frame.visible = true
    sprite.texture = load("res://battle/sprites/front/" + familiar.species.name.to_lower().replace(" ", "-") + ".png")

    visible = true

func open_spell_page(index: int):
    familiar_index = index
    var familiar = player_party.familiars[index]

    page = Page.SPELLS
    page_label.text = "SPELLS"

    name_label.visible = false
    health_cluster.visible = false
    stat_cluster.visible = false
    sprite_frame.visible = false

    mini_header.visible = true
    mini_header_mini.texture = load("res://battle/sprites/minis/" + familiar.species.name.to_lower().replace(" ", "-") + ".png")
    mini_name_label.text = familiar.get_display_name()
    mini_level_label.text = "Lv" + str(familiar.level)
    mini_type_value.text = Types.Type.keys()[familiar.species.type]
    mini_type_icon.frame = familiar.species.type as int

    var spell_names: Array[String] = []
    for spell in familiar.spells:
        spell_names.append(spell.name)
    prepared_spells.open_with(spell_names)
    open_spell_info()

func open_spell_info():
    spell_info.visible = true
    spell_desc.visible = true

    var spell: Spell
    if prepared_spells.visible:
        spell = player_party.familiars[familiar_index].spells[prepared_spells.cursor_index.y]
    else:
        return

    spell_info_power_label.text = "POWER: " + str(spell.power)
    spell_info_accuracy_label.text = "ACCURACY: " + str(spell.accuracy)
    spell_info_damage_type_icon.frame = 0 if spell.damage_type == Spell.DamageType.PHYSICAL else 1
    spell_info_damage_type_label.text = "PHYSICAL" if spell.damage_type == Spell.DamageType.PHYSICAL else "MAGICAL"
    spell_info_spell_type_icon.frame = spell.type
    spell_info_spell_type_label.text = Types.Type.keys()[spell.type]

    spell_desc_label.text = spell.desc

func _process(_delta):
    if not visible:
        return
    if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left"):
        if page == Page.STATS:
            open_spell_page(familiar_index)
        elif page == Page.SPELLS:
            open_stats_page(familiar_index)
    if Input.is_action_just_pressed("back"):
        emit_signal("finished")
