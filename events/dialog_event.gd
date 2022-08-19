extends Node

onready var dialog = get_node("/root/world/ui/dialog")

export(Array, String) var lines

func play():
    var _lines = dialog.split_lines(lines)
    for line in _lines:
        dialog.open(line)
        yield(dialog, "finished")