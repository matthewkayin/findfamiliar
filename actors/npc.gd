extends Actor

enum PathAction {
    MOVE,
    WAIT,
    FACE
}

onready var timer = $timer

export(Array, String) var path

var _path = []
var path_index = -1
var path_waiting = false
var is_pathing = true
var interact_event = null

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    var _ret_val = self.connect("took_step", self, "_on_took_step")

    interact_event = get_node_or_null("interact_event")
    if interact_event != null:
        add_to_group("interactables")

    # parse path
    _path = []
    for path_action in path:
        var path_parts = path_action.split(",")
        if path_parts[0] == "move":
            var direction
            for i in range(0, 4):
                if Direction.NAMES[i] == path_parts[1]:
                    direction = Direction.VECTORS[i]
                    break
            for _i in range(0, int(path_parts[2])):
                _path.append({
                    "action": PathAction.MOVE,
                    "direction": direction
                })
        elif path_parts[0] == "wait":
            _path.append({
                "action": PathAction.WAIT,
                "duration": float(path_parts[1])
            })
        elif path_parts[0] == "face":
            var direction
            for i in range(0, 4):
                if Direction.NAMES[i] == path_parts[1]:
                    direction = Direction.VECTORS[i]
                    break
            _path.append({
                "action": PathAction.FACE,
                "direction": direction
            })

func is_free_to_talk():
    return not is_moving()

func interact():
    is_pathing = false
    yield(interact_event.play(), "completed")
    is_pathing = true

func _on_timeout():
    path_waiting = false

func _on_took_step():
    path_waiting = false

func _update(delta):
    step_path()
    ._update(delta)

func step_path():
    if not is_pathing:
        return
    while not path_waiting:
        path_index = (path_index + 1) % _path.size()
        if _path[path_index].action == PathAction.MOVE:
            path_waiting = true
        elif _path[path_index].action == PathAction.WAIT:
            path_waiting = true
            timer.start(_path[path_index].duration)
        elif _path[path_index].action == PathAction.FACE:
            facing_direction = _path[path_index].direction
    if path_waiting and _path[path_index].action == PathAction.MOVE and not is_moving():
        facing_direction = _path[path_index].direction
        try_move(_path[path_index].direction)
