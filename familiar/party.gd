extends Node
class_name Party

var familiars: Array[Familiar] = []
var familiar_order: Array[int] = []
var items: Dictionary = {}
var enemy_witch_name: String
var enemy_witch_sprite: Texture2D
var enemy_lose_message: String

func get_familiar(index: int) -> Familiar:
    return familiars[familiar_order[index]]

func add_familiar(familiar: Familiar):
    familiars.append(familiar)
    familiar_order.append(familiar_order.size())

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

    get_familiar(0).has_participated = true

func after_battle():
    # Recall the party order
    familiar_order.clear()
    for i in range(0, familiars.size()):
        familiar_order.append(i)

    # clear conditions
    for familiar in familiars:
        familiar.clear_stat_mods()
        if familiar.condition != Condition.Type.NONE and not Condition.INFO[familiar.condition].stays_after_battle:
            familiar.condition = Condition.Type.NONE

func switch(index_a: int, index_b: int):
    var temp = familiar_order[index_a]
    familiar_order[index_a] = familiar_order[index_b]
    familiar_order[index_b] = temp

func hard_switch(index_a: int, index_b: int):
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
        var familiar = get_familiar(index)
        familiar.health = min(familiar.health + item.value, familiar.max_health)
