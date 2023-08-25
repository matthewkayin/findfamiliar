extends Node
class_name Party

var mana: int = 0
var old_familiar_order: Array[Familiar] = []
var familiars: Array[Familiar] = []
var items: Dictionary = {}
var burned_out: bool = false

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
    # if burned out, skip turn
    if burned_out:
        burned_out = false
    else:
        mana = 3 
    
    # reset flags
    for familiar in familiars:
        if not familiar.is_living():
            continue
        familiar.has_attacked = false
        familiar.has_switched = false
        familiar.has_used_item = false
    familiars[0].has_switched = true

func before_battle():
    # Remember the party order
    old_familiar_order = []
    for i in range(0, familiars.size()):
        old_familiar_order.append(familiars[i])

    # Ensure familiar 0 is the first living familiar
    var first_living_index: int = -1
    for i in range(0, familiars.size()):
        if familiars[i].is_living():
            first_living_index = i
            break
    if first_living_index != -1 and first_living_index != 0:
        switch(0, first_living_index)

func after_battle():
    # Recall the party order
    familiars = []
    for i in range(0, familiars.size()):
        familiars.append(old_familiar_order[i])
    
    # clear conditions
    for familiar in familiars:
        familiar.conditions.clear()

func get_switch_cost(to_index: int) -> int:
    var current_familiar_affinities = Types.INFO[familiars[0].species.type].affinities
    if current_familiar_affinities.has(familiars[to_index].species.type):
        var third_index = 1 if to_index == 2 else 1
        if familiars.size() == 3 and current_familiar_affinities.has[familiars[third_index].type]:
            return 0
        else:
            return 1
    else:
        return 2

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
