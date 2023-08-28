class_name Types

enum Type {
    NEUTRAL,
    WATER,
    FIRE,
    DARK,
    NATURE,
    EARTH,
    LIGHTNING
}

const INFO = {
    Type.NEUTRAL: {
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
            Type.NATURE,
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