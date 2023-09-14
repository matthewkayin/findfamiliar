extends Resource
class_name Species

@export var name: String
@export var type: Types.Type
@export_multiline var desc: String

@export_group("Stats")
@export_range(0, 255, 1) var base_health: int
@export_range(0, 255, 1) var base_strength: int
@export_range(0, 255, 1) var base_intellect: int
@export_range(0, 255, 1) var base_defense: int
@export_range(0, 255, 1) var base_agility: int

@export_group("Misc Stats")
@export_range(0, 255, 1) var catch_rate: int
@export_range(0, 255, 1) var exp_yield: int

@export_group("Spells")
@export var learn_spells: Array[LearnSpell]