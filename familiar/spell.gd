extends Resource
class_name Spell

enum DamageType {
    PHYSICAL,
    MAGICAL,
    NONE
}

enum StatMod {
    NONE = 0,
    UP = 1,
    UP2 = 2,
    DOWN = -1,
    DOWN2 = -2
}

enum ConditionTarget {
    NONE,
    SELF,
    OPPONENT
}

@export var name: String
@export var type: Types.Type
@export var animation: BattleAnimator.SpellAnimation
@export_multiline var desc: String

@export var power: int
@export var damage_type: DamageType
@export var accuracy: int
@export var condition_accuracy: int

@export var condition_target: ConditionTarget = ConditionTarget.NONE
@export var condition: Condition.Type = Condition.Type.NONE
@export var strength_mod: StatMod
@export var intellect_mod: StatMod
@export var defense_mod: StatMod
@export var agility_mod: StatMod
