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
        "weak": [
            Type.WATER,
            Type.EARTH
        ],
        "resist": [
            Type.NATURE,
            Type.POISON
        ]
    },
    Type.WATER: {
        "weak": [
            Type.NATURE,
            Type.POISON,
            Type.STORM
        ],
        "resist": [
            Type.FIRE,
            Type.EARTH
        ]
    },
    Type.NATURE: {
        "weak": [
            Type.FIRE,
            Type.POISON,
        ],
        "resist": [
            Type.WATER,
            Type.EARTH
        ]
    },
    Type.EARTH: {
        "weak": [
            Type.WATER,
            Type.NATURE
        ],
        "resist": [
            Type.FIRE,
            Type.POISON
        ]
    },
    Type.STORM: {
        "weak": [
            Type.EARTH
        ],
        "resist": [
            Type.WATER,
        ]
    },
    Type.POISON: {
        "weak": [
            Type.EARTH,
            Type.FIRE
        ],
        "resist": [
            Type.WATER,

        ]
    },
    Type.VOIDT: {
        "weak": [
        ],
        "resist": [
        ]
    }
}