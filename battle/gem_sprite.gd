extends AnimatedSprite2D

enum GemAnimation {
    NONE,
    THROW,
    BOUNCE,
    BOUNCING,
    WOBBLE
}

const origin: Vector2 = Vector2(84, 260)
const throw_target_position: Vector2 = Vector2(256, 80)
const fall_target_position: Vector2 = Vector2(256, 108)

var interpolate_value: float = 0.0
var interpolate_value2: float = 0.0
var current_animation: GemAnimation = GemAnimation.NONE

func _ready():
    visible = false
    play("default")

func animate_throw():
    play("default")
    position = origin
    visible = true
    
    current_animation = GemAnimation.THROW

    interpolate_value = 0.0
    var itween = get_tree().create_tween()
    itween.tween_property(self, "interpolate_value", 1.0, 1.0)
    itween.tween_interval(0.1)
    await itween.finished

    current_animation = GemAnimation.NONE
    position = throw_target_position

func animate_fall():
    current_animation = GemAnimation.BOUNCE
    interpolate_value = 0.0
    interpolate_value2 = 0.0

    var itween = get_tree().create_tween()
    itween.tween_interval(0.25)
    itween.tween_property(self, "position", fall_target_position, 0.4)
    itween.tween_property(self, "interpolate_value", 1.0, 0.4)
    itween.tween_property(self, "interpolate_value2", 1.0, 0.4)
    await itween.finished

    position = fall_target_position
    rotation = 0

    current_animation = GemAnimation.NONE

func animate_ticks(num_ticks: int):
    var itween = get_tree().create_tween()
    itween.tween_interval(0.5)
    await itween.finished
    for i in range(0, num_ticks):
        play("flash")
        await self.animation_finished
        var itween2 = get_tree().create_tween()
        itween2.tween_interval(0.5)
        await itween2.finished

func _process(_delta):
    if current_animation == GemAnimation.THROW:
        position.x = origin.x + ((throw_target_position.x - origin.x) * interpolate_value)
        position.y = origin.y - (origin.y * sin(2.36 * interpolate_value))
    elif current_animation == GemAnimation.BOUNCE:
        if interpolate_value > 0.0:
            current_animation = GemAnimation.BOUNCING
    if current_animation == GemAnimation.BOUNCING:
        position.y = fall_target_position.y - (12 * sin(3.14 * interpolate_value))
        if interpolate_value <= 0.33:
            rotation_degrees = -10 * (interpolate_value / 0.33)
        else: 
            rotation_degrees = -10 + (20 * ((interpolate_value - 0.33) / 0.67))
        if interpolate_value2 > 0.0:
            current_animation = GemAnimation.WOBBLE
    elif current_animation == GemAnimation.WOBBLE:
        if interpolate_value2 <= 0.67:
            rotation_degrees = 10  - (15 * (interpolate_value2 / 0.67))
        else: 
            rotation_degrees = -5 + (5 * ((interpolate_value2 - 0.67) / 0.33))