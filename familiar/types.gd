class_name Types

enum Type {
    FIRE,
    WATER,
    EARTH,
    AIR,
    SPIRIT
}

const NAME = {
    Type.FIRE: "FIRE",
    Type.WATER: "WATER",
    Type.EARTH: "EARTH",
    Type.AIR: "AIR",
    Type.SPIRIT: "SPIRIT"
}

const INFO = {
    Type.FIRE: {
        "weaknesses": [
            Type.WATER,
            Type.AIR
        ],
        "resistances": [
            Type.EARTH,
            Type.SPIRIT
        ],
        "affinities": [
            Type.AIR,
            Type.SPIRIT
        ]
    },
    Type.WATER: {
        "weaknesses": [
            Type.SPIRIT,
            Type.EARTH
        ],
        "resistances": [
            Type.FIRE,
            Type.AIR
        ],
        "affinities": [
            Type.EARTH,
            Type.AIR
        ]
    },
    Type.EARTH: {
        "weaknesses": [
            Type.FIRE,
            Type.SPIRIT
        ],
        "resistances": [
            Type.AIR,
            Type.WATER
        ],
        "affinities": [
            Type.WATER,
            Type.SPIRIT
        ]
    },
    Type.AIR: {
        "weaknesses": [
            Type.EARTH,
            Type.AIR
        ],
        "resistances": [
            Type.FIRE,
            Type.SPIRIT
        ],
        "affinities": [
            Type.WATER,
            Type.FIRE
        ]
    },
    Type.SPIRIT: {
        "weaknesses": [
            Type.FIRE,
            Type.AIR
        ],
        "resistances": [
            Type.WATER,
            Type.EARTH
        ],
        "affinities": [
            Type.EARTH,
            Type.FIRE
        ]
    }
}