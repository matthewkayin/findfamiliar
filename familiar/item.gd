extends Resource
class_name Item

enum ItemType {
    GEM,
    HEALING
}

@export var name: String
@export var type: ItemType
@export_multiline var desc: String
@export var value: int