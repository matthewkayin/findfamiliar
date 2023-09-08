extends Node2D
class_name World

const TILE_SIZE: int = 16
const DIRECTIONS = {
    "up": Vector2.UP,
    "right": Vector2.RIGHT,
    "down": Vector2.DOWN,
    "left": Vector2.LEFT
}
const TALLGRASS_COORDS = Vector2i(2, 1)

@onready var tilemap = $tilemap
@onready var player = $actors/player
@onready var transition = $ui/transition

@export_range(1, 100, 1) var wild_min_level: int = 1
@export_range(1, 100, 1) var wild_max_level: int = 1
@export var wild_familiars: Array[WildFamiliar]

var tile_blocked

func _ready():
    pass

static func get_direction_name(from_direction: Vector2) -> String:
    for direction_name in DIRECTIONS.keys():
        if DIRECTIONS[direction_name] == from_direction:
            return direction_name
    return ""

func is_tile_blocked(coordinate: Vector2):
    for walker in get_tree().get_nodes_in_group("walkers"):
        if walker.is_moving and coordinate == walker.next_tile_position:
            return true
        elif walker.position == coordinate:
            return true
    return tilemap.get_cell_tile_data(0, coordinate / TILE_SIZE).get_custom_data("blocked")

func is_tall_grass(coordinate: Vector2):
    return tilemap.get_cell_atlas_coords(0, coordinate / TILE_SIZE) == TALLGRASS_COORDS

func check_for_encounter(coordinate: Vector2):
    var encounter_rate = tilemap.get_cell_tile_data(0, coordinate / TILE_SIZE).get_custom_data("encounter_rate")
    var encountered_familiar = randi_range(0, 255) < encounter_rate
    if not encountered_familiar:
        return null
    
    var familiar_level = randi_range(wild_min_level, wild_max_level)
    var familiar_roll = randf_range(0, 1)
    var rate = 0
    for wild_familiar in wild_familiars:
        rate += wild_familiar.rate
        if familiar_roll <= rate:
            var familiar = Familiar.new(wild_familiar.species, familiar_level)
            return familiar

    print("error! no familiar found on wild roll!")
    return null

func _process(_delta):
    pass
