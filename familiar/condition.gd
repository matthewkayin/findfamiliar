class_name Condition

enum Type {
    STR_UP,
    STR_DOWN,
    INT_UP,
    INT_DOWN,
    DEF_UP,
    DEF_DOWN,
    AGI_UP,
    AGI_DOWN,
    BURN,
    SLEEP,
    TRAPPED
}

enum Target {
    SELF,
    PARTY,
    OPPONENT
}

const TTL_INDEFINITE = -1

const INFO = {
    Type.STR_UP: {
        "opposites": [Type.STR_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nStrength rose!",
        "reapply_message": "'s\nStrength buff\nwas extended!"
    },
    Type.STR_DOWN: {
        "opposites": [Type.STR_UP],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nStrength fell!",
        "reapply_message": "'s\nStrength debuff\nwas extended!"
    },
    Type.INT_UP: {
        "opposites": [Type.INT_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nIntelligence rose!",
        "reapply_message": "'s\nIntelligence buff\nwas extended!"
    },
    Type.INT_DOWN: {
        "opposites": [Type.INT_UP],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nIntelligence fell!",
        "reapply_message": "'s\nIntelligence debuff\nwas extended!"
    },
    Type.DEF_UP: {
        "opposites": [Type.DEF_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nDefense rose!",
        "reapply_message": "'s\nDefense buff\nwas extended!"
    },
    Type.DEF_DOWN: {
        "opposites": [Type.DEF_UP],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nDefense fell!",
        "reapply_message": "'s\nDefense debuff\nwas extended!"
    },
    Type.AGI_UP: {
        "opposites": [Type.AGI_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nAgility rose!",
        "reapply_message": "'s\nAgility buff\nwas extended!"
    },
    Type.AGI_DOWN: {
        "opposites": [Type.AGI_UP],
        "apply_anyway": false,
        "ttl": 3,
        "apply_message": "'s\nAgility fell!",
        "reapply_message": "'s\nAgility debuff\nwas extended!"
    },
    Type.BURN: {
        "opposites": [Type.SLEEP, Type.TRAPPED],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "apply_message": " was\nburned!",
        "reapply_message": " is\nalready burned!"
    },
    Type.SLEEP: {
        "opposites": [Type.BURN, Type.TRAPPED],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "apply_message": " fell\nasleep!",
        "reapply_message": " is\nalready asleep!"
    },
    Type.TRAPPED: {
        "opposites": [Type.BURN, Type.SLEEP],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "apply_message": " was\ntrapped!",
        "reapply_message": " is\nalready trapped!"
    },
}