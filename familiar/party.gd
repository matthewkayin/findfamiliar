extends Node
class_name Party

var old_familiar_order: Array[Familiar] = []
var familiars: Array[Familiar] = []
var items: Dictionary = {}

func get_living_familiar_count():
    var count = 0
    for familiar in familiars:
        if familiar.is_living():
            count += 1
    return count

func is_defeated() -> bool:
    for familiar in familiars:
        if familiar.is_living():
            return false
    return true

func before_turn():
    pass

func before_battle():
    # Remember the party order
    old_familiar_order = []
    for i in range(0, familiars.size()):
        old_familiar_order.append(familiars[i])

    # Reset participation flags
    for familiar in familiars:
        familiar.has_participated = false

    # Ensure familiar 0 is the first living familiar
    var first_living_index: int = -1
    for i in range(0, familiars.size()):
        if familiars[i].is_living():
            first_living_index = i
            break
    if first_living_index != -1 and first_living_index != 0:
        switch(0, first_living_index)

    familiars[0].has_participated = true

func after_battle():
    # Recall the party order
    familiars = []
    for i in range(0, familiars.size()):
        familiars.append(old_familiar_order[i])
    
    # clear conditions
    for familiar in familiars:
        for stat_name in Familiar.STAT_NAMES:
            familiar[stat_name + "_stage"] = 0
        if familiar.condition != Condition.Type.NONE and not Condition.INFO[familiar.condition].stays_after_battle:
            familiar.condition = Condition.Type.NONE

func switch(index_a: int, index_b: int):
    var temp = familiars[index_a]
    familiars[index_a] = familiars[index_b]
    familiars[index_b] = temp

func add_item(item: Item, quantity: int = 1):
    if not items.has(item):
        items[item] = 0
    items[item] += quantity

func remove_item(item: Item, quantity: int = 1):
    if not items.has(item):
        return
    elif items[item] <= quantity:
        items.erase(item)
    else:
        items[item] -= quantity

func use_item(item: Item, index: int):
    remove_item(item, 1)

    if item.type == Item.ItemType.HEALING:
        familiars[index].health = min(familiars[index].health + item.value, familiars[index].max_health)
    familiars[index].has_used_item = true
