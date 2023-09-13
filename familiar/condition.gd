class_name Condition

# each Type value is equal to the frame in conditions.png
enum Type {
    NONE = 0,
    BURNED = 1,
    ASLEEP = 2,
    POISONED = 3,
    PARALYZED = 4 
}

const INFO = {
    Type.BURNED: {
        "icon_frame": 5,
        "apply_message": "\nwas burned!",
        "cure_message": "'s\nburn was cured!",
        "stays_after_battle": true
    },
    Type.ASLEEP: {
        "icon_frame": 6,
        "apply_message": "\nfell asleep!",
        "cure_message": "\nwoke up!",
        "stays_after_battle": false
    },
    Type.POISONED: {
        "icon_frame": 7,
        "apply_message": "\nwas poisoned!",
        "cure_message": "'s\npoison was cured!",
        "stays_after_battle": true
    },
    Type.PARALYZED: {
        "icon_frame": 8,
        "apply_message": "\nwas paralyzed!",
        "cure_message": "'s\nparalysis was cured!",
        "stays_after_battle": true
    }
}
