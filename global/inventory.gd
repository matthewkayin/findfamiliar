extends Node

var items = []

func _ready():
    for category in Item.Category.values():
        items.append([])
    var potion = load("res://data/items/potion.tres")
    var hipotion = load("res://data/items/hi-potion.tres")
    var ruby = load("res://data/items/ruby.tres")
    add_item(potion, 2)
    add_item(hipotion, 5)
    add_item(ruby, 5)

func add_item(item: Item, qty=1):
    for existing_item in items[item.category]:
        if existing_item.item.name == item.name:
            existing_item.qty += qty
            return
    items[item.category].append({
        "item": item,
        "qty": qty
    })

func remove_item(item: Item, qty=1):
    for i in range(0, items[item.category].size()):
        if items[item.category][i].item.name == item.name:
            items[item.category][i].qty -= qty
            if items[item.category][i].qty <= 0:
                items[item.category].remove(i)
                return

func get_count_of(item: Item):
    for existing_item in items[item.category]:
        if existing_item.item.name == item.name:
            return existing_item.qty
    return 0

func use_item(item: Item, target: Familiar) -> String:
    var use_string = ""

    if item.category == Item.Category.MEDICINE:
        if item.medicine_effect == Item.MedicineEffect.HEAL:
            var old_target_health = target.health
            target.change_health(item.medicine_effect_value)
            var health_gained = target.health - old_target_health
            use_string = target.get_name() + " gained " + String(health_gained) + " HP!"
    remove_item(item)
    return use_string
