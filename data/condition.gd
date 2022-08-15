class_name Conditions

enum Condition {
    ATTACK_UP,
    ATTACK_DOWN,
    DEFENSE_UP,
    DEFENSE_DOWN,
    SPEED_UP,
    SPEED_DOWN,
    PARALYZED,
    POISONED
}

const DURATION_INDEFINITE = -1
const OPPOSITE_NONE = -1
const INFO = {
    Condition.ATTACK_UP: {
        "duration": 3,
        "opposite": Condition.ATTACK_DOWN,
        "apply_message": "'s attack went up!",
        "remove_message": "'s attack returned to normal!",
        "noeffect_message": "'s attack is already raised!",
    },
    Condition.ATTACK_DOWN: {
        "duration": 3,
        "opposite": Condition.ATTACK_UP,
        "apply_message": "'s attack went down!",
        "remove_message": "'s attack returned to normal!",
        "noeffect_message": "'s attack is already lowered!",
    },
    Condition.DEFENSE_UP: {
        "duration": 3,
        "opposite": Condition.DEFENSE_DOWN,
        "apply_message": "'s defense went up!",
        "remove_message": "'s defense returned to normal!",
        "noeffect_message": "'s defense is already raised!",
    },
    Condition.DEFENSE_DOWN: {
        "duration": 3,
        "opposite": Condition.DEFENSE_UP,
        "apply_message": "'s defense went down!",
        "remove_message": "'s defense returned to normal!",
        "noeffect_message": "'s defense is already lowered!",
    },
    Condition.SPEED_UP: {
        "duration": 3,
        "opposite": Condition.SPEED_DOWN,
        "apply_message": "'s speed went up!",
        "remove_message": "'s speed returned to normal!",
        "noeffect_message": "'s speed is already raised!",
    },
    Condition.SPEED_DOWN: {
        "duration": 3,
        "opposite": Condition.SPEED_UP,
        "apply_message": "'s speed went down!",
        "remove_message": "'s speed returned to normal!",
        "noeffect_message": "'s speed is already lowered!",
    },
    Condition.PARALYZED: {
        "duration": DURATION_INDEFINITE,
        "opposite": OPPOSITE_NONE,
        "apply_message": " was paralyzed!",
        "remove_message": " was cured of its paralysis!",
        "noeffect_message": " is already paralyzed!",
    },
    Condition.POISONED: {
        "duration": DURATION_INDEFINITE,
        "opposite": OPPOSITE_NONE,
        "apply_message": " was poisoned!",
        "remove_message": " was cured of its poisoning!",
        "noeffect_message": " is already poisoned!",
    },
}