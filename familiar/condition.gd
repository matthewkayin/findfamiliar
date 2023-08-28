class_name Condition

# each Type value is equal to the frame in conditions.png
enum Type {
    NONE = 0,
    BURN = 20,
    SLEEP = 21 
}

const INFO = {
    Type.BURN: {
        "apply_message": "\nwas burned!",
        "cure_message": "\nburn was cured!",
        "animation": BattleAnimator.SpellAnimation.NONE
    },
    Type.SLEEP: {
        "apply_message": "\nfell asleep!",
        "cure_message": "\nwoke up!",
        "animation": BattleAnimator.SpellAnimation.NONE
    }
}
