extends NinePatchRect

signal finished

onready var inventory = get_node("/root/Inventory")
onready var party_menu = get_parent().get_node("party_menu")

onready var category_label = $category/label
onready var category_nav_left = $category/nav_left
onready var category_nav_right = $category/nav_right
onready var desc_label = $desc/label
onready var cursor = $list/cursor
onready var switch_cursor = $list/switch_cursor
onready var list_nav_up = $list/nav_up
onready var list_nav_down = $list/nav_down
onready var item_label_box = $list/items
onready var item_labels = $list/items.get_children()
onready var timer = $timer
onready var prompt = $inventory_prompt
onready var prompt_nouse = $inventory_prompt_nouse

const LIST_SIZE = 9

var category = Item.Category.MEDICINE
var cursor_index = 0
var switch_index = -1
var list_offset = 0
var just_opened = false
var switch_cursor_visible = false
var in_battle = false
var item_used = false

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    prompt.connect("finished", self, "_on_inventory_prompt_finished")
    prompt_nouse.connect("finished", self, "_on_inventory_prompt_nouse_finished")
    party_menu.connect("finished", self, "_on_party_menu_finished")

func _on_timeout():
    switch_cursor_visible = not switch_cursor_visible
    refresh_switch_cursor()

func _on_inventory_prompt_finished():
    if prompt.choice == "SWITCH":
        begin_switch()
    elif prompt.choice == "USE":
        party_menu.context = PartyMenu.Context.ITEM
        party_menu.item = inventory.items[category][list_offset + cursor_index].item
        party_menu.item_used = false
        party_menu.item_in_battle = in_battle
        party_menu.open()
        visible = false

func _on_inventory_prompt_nouse_finished():
    if prompt_nouse.choice == "SWITCH":
        begin_switch()

func _on_party_menu_finished():
    visible = true
    just_opened = true
    if in_battle:
        if party_menu.item_used:
            item_used = true
            close()
    else:
        refresh()

func begin_switch():
    switch_index = list_offset + cursor_index
    timer.start(0.3)
    refresh()

func end_switch():
    switch_index = -1
    timer.stop()
    refresh()

func refresh_category():
    category_label.text = Item.Category.keys()[category]
    category_nav_left.visible = category != 0
    category_nav_right.visible = category != Item.Category.keys().size() - 1

func refresh_desc():
    if not item_labels[cursor_index].visible:
        desc_label.text = ""
        return
    desc_label.text = inventory.items[category][list_offset + cursor_index].item.desc

func refresh_list():
    for item_label in item_labels:
        item_label.visible = false
    if list_offset + LIST_SIZE > inventory.items[category].size():
        list_offset = 0
    for i in range(0, min(inventory.items[category].size(), LIST_SIZE)):
        item_labels[i].text = inventory.items[category][list_offset + i].item.name
        item_labels[i].get_child(0).text = "x" + String(inventory.items[category][list_offset + i].qty)
        item_labels[i].visible = true
    list_nav_up.visible = list_offset > 0
    list_nav_down.visible = list_offset + LIST_SIZE < inventory.items[category].size()

func refresh_cursor():
    if not item_labels[cursor_index].visible:
        cursor.visible = false
        return
    cursor.position.y = item_label_box.rect_position.y + item_labels[cursor_index].rect_position.y - 2.5
    cursor.visible = true

func refresh_switch_cursor():
    if switch_index == -1:
        switch_cursor.visible = false
        return
    var switch_cursor_index = switch_index - list_offset
    if switch_cursor_index < 0 or switch_cursor_index >= LIST_SIZE:
        switch_cursor.visible = false
        return
    switch_cursor.position.y = item_label_box.rect_position.y + item_labels[switch_cursor_index].rect_position.y - 2.5

    switch_cursor.position.x = cursor.position.x
    switch_cursor.visible = switch_cursor_visible

func open():
    category = Item.Category.MEDICINE
    cursor_index = 0
    list_offset = 0
    refresh()
    item_used = false
    just_opened = true
    visible = true

func refresh():
    refresh_category()
    refresh_list()
    refresh_desc()
    refresh_cursor()
    refresh_switch_cursor()

func close(should_emit_signal=true):
    visible = false
    if should_emit_signal:
        emit_signal("finished")

func _process(_delta):
    if not visible:
        return
    if just_opened:
        just_opened = false
        return
    if prompt.visible or prompt_nouse.visible:
        return
    if party_menu.visible:
        return

    if Input.is_action_just_pressed("back"):
        if switch_index != -1:
            end_switch()
            return
        close()
        return
    if Input.is_action_just_pressed("left"):
        if category == 0:
            return
        if switch_index != -1:
            return
        category -= 1
        cursor_index = 0
        list_offset = 0
        refresh()
    if Input.is_action_just_pressed("right"):
        if category == Item.Category.keys().size() - 1:
            return
        if switch_index != -1:
            return
        category += 1
        cursor_index = 0
        list_offset = 0
        refresh()
    if Input.is_action_just_pressed("up"):
        if cursor_index > 0:
            cursor_index -= 1
        elif list_nav_up.visible:
            list_offset -= 1
        refresh()
    if Input.is_action_just_pressed("down"):
        if cursor_index < min(LIST_SIZE - 1, inventory.items[category].size() - 1):
            cursor_index += 1
        elif list_nav_down.visible:
            list_offset += 1
        refresh()
    elif Input.is_action_just_pressed("action"):
        if switch_index != -1:
            var temp = inventory.items[category][switch_index]
            inventory.items[category][switch_index] = inventory.items[category][list_offset + cursor_index]
            inventory.items[category][list_offset + cursor_index] = temp
            end_switch()
            return

        if in_battle and not inventory.items[category][list_offset + cursor_index].item.use_in_battle:
            prompt_nouse.open()
        else:
            prompt.open()
