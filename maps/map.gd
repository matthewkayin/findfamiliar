extends TileMap

var size: Vector2
var tile_empty 

func _ready():
    # Calculate the map coordinates
    size = Vector2.ZERO
    while get_cell(int(size.x), 0) != INVALID_CELL:
        size.x += 1
    while get_cell(0, int(size.y)) != INVALID_CELL:
        size.y += 1

    # Initialize the tile collisions array
    tile_empty = []
    for x in range(0, size.x):
        tile_empty.append([])
        for y in range(0, size.y):
            var tile_has_colliders = tile_set.tile_get_shape_count(get_cell(x, y)) != 0
            tile_empty[x].append(not tile_has_colliders)

func is_tile_free(tile_position: Vector2) -> bool:
    var tile_coordinate = world_to_map(tile_position)
    return get_cellv(tile_coordinate) != INVALID_CELL and tile_empty[tile_coordinate.x][tile_coordinate.y]

func free_tile(tile_position: Vector2):
    var tile_coordinate = world_to_map(tile_position)
    tile_empty[tile_coordinate.x][tile_coordinate.y] = true

func reserve_tile(tile_position: Vector2):
    var tile_coordinate = world_to_map(tile_position)
    tile_empty[tile_coordinate.x][tile_coordinate.y] = false