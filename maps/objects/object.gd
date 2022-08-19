extends Sprite

export(Array, Vector2) var exempt_tiles

func place_reservation():
    var tilemap = get_parent().get_parent().get_node("tilemap")

    var size_in_tiles = Vector2(texture.get_width() / 16, texture.get_height() / 16)
    for x in range(0, size_in_tiles.x):
        for y in range(0, size_in_tiles.y):
            var tile = Vector2(x, y)
            if exempt_tiles.has(tile):
                continue
            tilemap.reserve_tile(position + (tile * 32))
