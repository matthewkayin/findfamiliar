extends Node

var spells = []

func _ready():
    spells.append(load("res://data/spells/witch_bolt.tres"))
    spells.append(load("res://data/spells/fire_bolt.tres"))
    spells.append(load("res://data/spells/shock.tres"))