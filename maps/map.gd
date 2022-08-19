extends TileMap

var size: Vector2
var origin: Vector2
var tile_empty 

func _ready():
    # Calculate the map coordinates
    var used_rect = get_used_rect()
    origin = used_rect.position
    size = used_rect.size

    # Initialize the tile collisions array
    tile_empty = []
    for x in range(0, size.x):
        tile_empty.append([])
        for _y in range(0, size.y):
            # var tile_has_colliders = tile_set.tile_get_shape_count(get_cell(x, y)) != 0
            # tile_empty[x].append(not tile_has_colliders)
            tile_empty[x].append(true)
    for cell in get_used_cells():
        var cell_tile_index = get_cellv(cell)
        if tile_set.tile_get_shape_count(cell_tile_index) == 0:
            continue
        var cell_origin = cell - origin
        var shape = tile_set.tile_get_shape(cell_tile_index, 0)
        var shape_size = Vector2.ZERO
        for point in shape.points:
            shape_size.x = max(shape_size.x, point.x)
            shape_size.y = max(shape_size.y, point.y)
        shape_size /= 16
        for x in range(0, shape_size.x):
            for y in range(0, shape_size.y):
                var blocked_tile = cell_origin + Vector2(x, y)
                if blocked_tile.y >= size.y or blocked_tile.x >= size.x:
                    continue
                tile_empty[blocked_tile.x][blocked_tile.y] = false

    # Have all child objects reserve their collision tiles
    for child in get_parent().get_node("objects").get_children():
        child.place_reservation()

func coord_in_bounds(coord: Vector2) -> bool:
    return coord.x >= origin.x and coord.x < origin.x + size.x and coord.y >= origin.y and coord.y < origin.y + size.y

func is_tile_free(tile_position: Vector2) -> bool:
    var tile_coordinate = tile_position / 32
    var tile_coordinate_offset = tile_coordinate - origin
    return coord_in_bounds(tile_coordinate) and tile_empty[tile_coordinate_offset.x][tile_coordinate_offset.y]

func free_tile(tile_position: Vector2):
    var tile_coordinate = tile_position / 32
    var tile_coordinate_offset = tile_coordinate - origin
    tile_empty[tile_coordinate_offset.x][tile_coordinate_offset.y] = true

func reserve_tile(tile_position: Vector2):
    var tile_coordinate = tile_position / 32
    var tile_coordinate_offset = tile_coordinate - origin
    tile_empty[tile_coordinate_offset.x][tile_coordinate_offset.y] = false
