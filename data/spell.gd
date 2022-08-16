extends Resource
class_name Spell

export var name: String
export(Types.Type) var type
export var desc: String

export var cast_cost: int
export var learn_cost: int

export var power: int
export var accuracy: int
export(Array, Conditions.Condition) var conditions
export(Array, float) var condition_rates