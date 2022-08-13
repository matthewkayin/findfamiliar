extends ChoiceDialog

onready var party_menu = get_parent().get_node("party_menu")

var in_submenu = false

func _ready():
    party_menu.connect("finished", self, "_on_party_menu_finished")

func _on_party_menu_finished():
    choice = ChoiceDialog.CHOOSING
    in_submenu = false
    just_opened = true

func _process(_delta):
    if in_submenu or not visible: 
        return
        
    if choice == "EXIT":
        close()
    elif choice == "FAMILIAR":
        party_menu.open()
        in_submenu = true
    else:
        choice = ChoiceDialog.CHOOSING