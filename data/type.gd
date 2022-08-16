class_name Types

enum Type {
    FIRE,
    WATER,
    NATURE,
    EARTH,
    STORM,
    POISON,
    VOIDT
}

const NAME = {
    Type.FIRE: "FIRE",
    Type.WATER: "WATER",
    Type.NATURE: "NATURE",
    Type.EARTH: "EARTH",
    Type.STORM: "STORM",
    Type.POISON: "POISON",
    Type.VOIDT: "VOID",
}

const INFO = {
    Type.FIRE: {
        "weaknesses": [
            Type.WATER,
            Type.EARTH
        ],
        "resistances": [
            Type.NATURE,
            Type.POISON
        ]
    },
    Type.WATER: {
        "weaknesses": [
            Type.NATURE,
            Type.POISON,
            Type.STORM
        ],
        "resistances": [
            Type.FIRE,
            Type.EARTH
        ]
    },
    Type.NATURE: {
        "weaknesses": [
            Type.FIRE,
            Type.POISON,
        ],
        "resistances": [
            Type.WATER,
            Type.EARTH
        ]
    },
    Type.EARTH: {
        "weaknesses": [
            Type.WATER,
            Type.NATURE
        ],
        "resistances": [
            Type.FIRE,
            Type.POISON
        ]
    },
    Type.STORM: {
        "weaknesses": [
            Type.EARTH
        ],
        "resistances": [
            Type.WATER,
        ]
    },
    Type.POISON: {
        "weaknesses": [
            Type.EARTH,
            Type.FIRE
        ],
        "resistances": [
            Type.WATER,

        ]
    },
    Type.VOIDT: {
        "weaknesses": [
            Type.FIRE
        ],
        "resistances": [
        ]
    }
}