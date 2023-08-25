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
        "icon_frame": 1,
        "apply_message": "'s\nStrength rose!",
        "reapply_message": "'s\nStrength buff\nwas extended!",
        "expire_message": "'s\nStrength returned\nto normal!"
    },
    Type.STR_DOWN: {
        "opposites": [Type.STR_UP],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 2,
        "apply_message": "'s\nStrength fell!",
        "reapply_message": "'s\nStrength debuff\nwas extended!",
        "expire_message": "'s\nStrength returned\nto normal!"
    },
    Type.INT_UP: {
        "opposites": [Type.INT_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 4,
        "apply_message": "'s\nIntellect rose!",
        "reapply_message": "'s\nIntellect buff\nwas extended!",
        "expire_message": "'s\nIntellect returned\nto normal!"
    },
    Type.INT_DOWN: {
        "opposites": [Type.INT_UP],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 5,
        "apply_message": "'s\nIntellect fell!",
        "reapply_message": "'s\nIntellect debuff\nwas extended!",
        "expire_message": "'s\nIntellect returned\nto normal!"
    },
    Type.DEF_UP: {
        "opposites": [Type.DEF_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 7,
        "apply_message": "'s\nDefense rose!",
        "reapply_message": "'s\nDefense buff\nwas extended!",
        "expire_message": "'s\nDefense returned\nto normal!"
    },
    Type.DEF_DOWN: {
        "opposites": [Type.DEF_UP],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 8,
        "apply_message": "'s\nDefense fell!",
        "reapply_message": "'s\nDefense debuff\nwas extended!",
        "expire_message": "'s\nDefense returned\nto normal!"
    },
    Type.AGI_UP: {
        "opposites": [Type.AGI_DOWN],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 10,
        "apply_message": "'s\nAgility rose!",
        "reapply_message": "'s\nAgility buff\nwas extended!",
        "expire_message": "'s\nAgility returned\nto normal!"
    },
    Type.AGI_DOWN: {
        "opposites": [Type.AGI_UP],
        "apply_anyway": false,
        "ttl": 3,
        "icon_frame": 11,
        "apply_message": "'s\nAgility fell!",
        "reapply_message": "'s\nAgility debuff\nwas extended!",
        "expire_message": "'s\nAgility returned\nto normal!"
    },
    Type.BURN: {
        "opposites": [Type.SLEEP, Type.TRAPPED],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "icon_frame": 12,
        "apply_message": "\nwas burned!",
        "reapply_message": "\nis already burned!",
        "expire_message": "'s\nburn was cured!"
    },
    Type.SLEEP: {
        "opposites": [Type.BURN, Type.TRAPPED],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "icon_frame": 13,
        "apply_message": "\nfell asleep!",
        "reapply_message": "\nis already asleep!",
        "expire_message": "\nwoke up!"
    },
    Type.TRAPPED: {
        "opposites": [Type.BURN, Type.SLEEP],
        "apply_anyway": true,
        "ttl": TTL_INDEFINITE,
        "icon_frame": 14,
        "apply_message": "\nwas trapped!",
        "reapply_message": "\nescaped its trap!"
    },
}