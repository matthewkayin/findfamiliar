extends Resource
class_name Spell

enum DamageType {
    PHYSICAL,
    MAGICAL,
    NONE
}

@export var name: String
@export var type: Types.Type
@export var animation: FamiliarSprite.SpellAnimation
@export_multiline var desc: String

@export var power: int
@export var damage_type: DamageType
@export var accuracy: int
@export var cost: int

@export var conditions: Array[Condition.Type]
@export var condition_target: Condition.Target
@export var condition_accuracy: int