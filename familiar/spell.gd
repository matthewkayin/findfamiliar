extends Resource
class_name Spell

enum DamageType {
    PHYSICAL,
    MAGICAL,
    NONE
}

enum ConditionTarget {
    NONE,
    SELF,
    OPPONENT
}

@export var name: String
@export var type: Types.Type
@export_multiline var desc: String

@export_group("Stats")
@export_range(0, 255, 1) var power: int
@export var damage_type: DamageType
@export_range(0, 100, 1) var accuracy: int
@export_range(0, 100, 1) var condition_accuracy: int

@export_group("Condition")
@export var condition_target: ConditionTarget = ConditionTarget.NONE
@export var condition: Condition.Type = Condition.Type.NONE
@export_range(-6, 6, 1) var strength_mod: int = 0
@export_range(-6, 6, 1) var intellect_mod: int = 0
@export_range(-6, 6, 1) var defense_mod: int = 0
@export_range(-6, 6, 1) var agility_mod: int = 0
