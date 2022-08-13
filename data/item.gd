extends Resource
class_name Item

enum Category {
    MEDICINE,
    GEM
}

enum MedicineEffect {
    HEAL,
}

export var name: String
export(Category) var category
export var desc: String

export var use_in_world: bool = true
export var use_in_battle: bool = true

export(MedicineEffect) var medicine_effect
export var medicine_effect_value: int