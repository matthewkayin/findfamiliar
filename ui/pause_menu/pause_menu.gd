extends ChoiceDialog

onready var party_menu = get_parent().get_node("party_menu")
onready var item_menu = get_parent().get_node("item_menu")

var in_submenu = false

func _ready():
    pass

func _process(_delta):
    if in_submenu or not visible: 
        return
        
    if choice == "EXIT":
        close()
    elif choice == "FAMILIAR":
        party_menu.open()
        in_submenu = true
        yield(party_menu, "finished")
        choice = ChoiceDialog.CHOOSING
        in_submenu = false
        just_opened = true
    elif choice == "ITEM":
        item_menu.open()
        in_submenu = true
        yield(item_menu, "finished")
        choice = ChoiceDialog.CHOOSING
        in_submenu = false
        just_opened = true
    else:
        choice = ChoiceDialog.CHOOSING