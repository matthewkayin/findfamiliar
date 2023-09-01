class_name Condition

# each Type value is equal to the frame in conditions.png
enum Type {
    NONE = 0,
    BURNED = 4,
    ASLEEP = 5,
    POISONED = 6,
    PARALYZED = 7
}

const INFO = {
    Type.BURNED: {
        "apply_message": "\nwas burned!",
        "cure_message": "'s\nburn was cured!",
        "animation": BattleAnimator.SpellAnimation.NONE,
        "stays_after_battle": true
    },
    Type.ASLEEP: {
        "apply_message": "\nfell asleep!",
        "cure_message": "\nwoke up!",
        "animation": BattleAnimator.SpellAnimation.NONE,
        "stays_after_battle": false
    },
    Type.POISONED: {
        "apply_message": "\nwas poisoned!",
        "cure_message": "'s\npoison was cured!",
        "animation": BattleAnimator.SpellAnimation.NONE,
        "stays_after_battle": true
    },
    Type.PARALYZED: {
        "apply_message": "\nwas paralyzed!",
        "cure_message": "'s\nparalysis was cured!",
        "animation": BattleAnimator.SpellAnimation.NONE,
        "stays_after_battle": true
    }
}
