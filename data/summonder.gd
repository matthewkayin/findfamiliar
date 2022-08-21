extends Resource
class_name Summoner

export var name: String
export(Resource) var texture
export var opener: String
export var closer: String
export var post_battle_dialog: String

export(Array, Resource) var party_species
export(Array, int) var party_level
export(Array, Array, Resource) var party_spells