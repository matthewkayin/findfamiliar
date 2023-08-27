extends NinePatchRect

@onready var label = $label

func _ready():
    pass

func open(item: Item):
    label.text = item.desc