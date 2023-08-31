class_name Types

enum Type {
    NORMAL = 0,
    WATER = 1,
    FIRE = 2,
    DARK = 3,
    NATURE = 4,
    EARTH = 5,
    LIGHTNING = 6
}

const INFO = {
    Type.NORMAL: {
        "weaknesses": [],
        "resistances": [],
    },
    Type.WATER: {
        "weaknesses": [
            Type.NATURE,
            Type.LIGHTNING
        ],
        "resistances": [
            Type.FIRE,
            Type.EARTH
        ]
    },
    Type.FIRE: {
        "weaknesses": [
            Type.WATER,
            Type.EARTH
        ],
        "resistances": [
            Type.DARK,
            Type.NATURE
        ]
    },
    Type.DARK: {
        "weaknesses": [
            Type.FIRE,
            Type.LIGHTNING
        ],
        "resistances": [
            Type.NATURE
        ]
    },
    Type.NATURE: {
        "weaknesses": [
            Type.DARK,
            Type.FIRE
        ],
        "resistances": [
            Type.EARTH,
            Type.WATER
        ]
    },
    Type.EARTH: {
        "weaknesses": [
            Type.NATURE,
            Type.WATER
        ],
        "resistances": [
            Type.LIGHTNING,
            Type.FIRE
        ]
    },
    Type.LIGHTNING: {
        "weaknesses": [
            Type.EARTH,
        ],
        "resistances": [
            Type.WATER,
            Type.DARK
        ]
    }
}