class_name Types

enum Type {
    NORMAL = 0,
    WATER = 1,
    FIRE = 2,
    DARK = 3,
    NATURE = 4,
    EARTH = 5,
    LIGHTNING = 6,
    AIR = 7,
    GHOST = 8,
    MIND = 9
}

const NO_EFFECT: float = 0.0
const SUPER_EFFECTIVE: float = 2.0
const NOT_EFFECTIVE: float = 0.5

const EFFECTIVENESS = {
    Type.NORMAL: {
        Type.GHOST: NO_EFFECT
    },
    Type.WATER: {
        Type.FIRE: SUPER_EFFECTIVE,
        Type.EARTH: SUPER_EFFECTIVE,
        Type.LIGHTNING: NOT_EFFECTIVE
    },
    Type.FIRE: {
        Type.DARK: SUPER_EFFECTIVE,
        Type.NATURE: SUPER_EFFECTIVE,
        Type.EARTH: NOT_EFFECTIVE,
        Type.AIR: NOT_EFFECTIVE
    },
    Type.DARK: {
        Type.NATURE: SUPER_EFFECTIVE,
        Type.GHOST: SUPER_EFFECTIVE,
        Type.FIRE: NOT_EFFECTIVE,
        Type.MIND: NOT_EFFECTIVE
    },
    Type.NATURE: {
        Type.EARTH: SUPER_EFFECTIVE,
        Type.WATER: SUPER_EFFECTIVE,
        Type.DARK: NOT_EFFECTIVE,
        Type.FIRE: SUPER_EFFECTIVE,
        Type.AIR: NOT_EFFECTIVE
    },
    Type.EARTH: {
        Type.FIRE: SUPER_EFFECTIVE,
        Type.LIGHTNING: SUPER_EFFECTIVE,
        Type.AIR: SUPER_EFFECTIVE,
        Type.WATER: NOT_EFFECTIVE,
        Type.MIND: NOT_EFFECTIVE,
        Type.NATURE: NOT_EFFECTIVE
    },
    Type.AIR: {
        Type.FIRE: SUPER_EFFECTIVE,
        Type.NATURE: SUPER_EFFECTIVE,
        Type.LIGHTNING: NOT_EFFECTIVE,
        Type.EARTH: NOT_EFFECTIVE
    },
    Type.LIGHTNING: {
        Type.AIR: SUPER_EFFECTIVE,
        Type.WATER: SUPER_EFFECTIVE,
        Type.EARTH: NOT_EFFECTIVE
    },
    Type.GHOST: {
        Type.NORMAL: NO_EFFECT,
        Type.MIND: SUPER_EFFECTIVE,
        Type.GHOST: SUPER_EFFECTIVE,
        Type.DARK: NOT_EFFECTIVE
    },
    Type.MIND: {
        Type.DARK: SUPER_EFFECTIVE,
        Type.EARTH: SUPER_EFFECTIVE,
        Type.GHOST: NOT_EFFECTIVE
    }
}