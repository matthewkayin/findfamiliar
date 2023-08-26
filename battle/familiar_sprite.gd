extends Sprite2D
class_name FamiliarSprite

enum SpellAnimation {
    NONE,
    SCRATCH
}

@onready var animation = $animation

@export var is_enemy: bool = false

func _ready():
    texture = null
    animation.visible = false

func animate_enter(species_name: String):
    var animate_tween = get_tree().create_tween()

    var face = "front" if is_enemy else "back"
    texture = load("res://battle/sprites/" + face + "/" + species_name.replace(" ", "-").to_lower() + ".png")
    position = Vector2(-64, 64) if is_enemy else Vector2(320, 192)
    visible = true

    animate_tween.tween_property(self, "position", Vector2(256, 64) if is_enemy else Vector2(56, 192), 2.0)
    await animate_tween.finished

func animate_exit():
    var animate_tween = get_tree().create_tween()

    animate_tween.tween_property(self, "position", Vector2(376, 64) if is_enemy else Vector2(-56, 192), 0.5)
    await animate_tween.finished

func animate_summon(species_name: String):
    position = Vector2(256, 64) if is_enemy else Vector2(48, 192)

    var face = "front" if is_enemy else "back"
    var species_sprite = load("res://battle/sprites/" + face + "/" + species_name.replace(" ", "-").to_lower() + ".png")
    texture = null
    region_enabled = false
    animation.visible = true
    animation.play("summon")
    await animation.animation_finished
    animation.visible = false
    texture = species_sprite

func animate_unsummon():
    texture = null
    animation.visible = true
    animation.play("unsummon")
    await animation.animation_finished
    animation.visible = false

func animate_attack():
    var animate_tween = get_tree().create_tween()

    var direction = -1 if is_enemy else 1
    var origin = position
    animate_tween.tween_property(self, "position", origin + Vector2(direction * 16, 0), 0.2)
    animate_tween.tween_property(self, "position", origin, 0.2)
    await animate_tween.finished

func animate_hurt(effectiveness: float):
    var speed_mod: float = 1.0
    if effectiveness == 2.0:
        speed_mod = 0.75
    elif effectiveness == 0.5:
        speed_mod = 1.25

    if is_enemy:
        for i in range(0, 3):
            visible = false
            var animate_tween = get_tree().create_tween()
            animate_tween.tween_interval(0.1 * speed_mod)
            await animate_tween.finished
            visible = true
            var animate_tween2 = get_tree().create_tween()
            animate_tween2.tween_interval(0.1 * speed_mod)
            await animate_tween2.finished
    else:
        var scene = get_parent()
        for i in range(0, 3):
            scene.position = Vector2(0, -2)
            var animate_tween = get_tree().create_tween()
            animate_tween.tween_interval(0.1 * speed_mod)
            await animate_tween.finished

            scene.position = Vector2(0, 2)
            var animate_tween2 = get_tree().create_tween()
            animate_tween2.tween_interval(0.1 * speed_mod)
            await animate_tween2.finished
        scene.position = Vector2.ZERO

func animate_faint():
    region_rect.size = get_rect().size
    region_enabled = true

    var animate_tween = get_tree().create_tween()
    animate_tween.tween_property(self, "position", position + Vector2(0, region_rect.size.y), 0.5)
    var animate_tween2 = get_tree().create_tween()
    animate_tween2.tween_property(self, "region_rect", Rect2(region_rect.position, Vector2(region_rect.size.x, 0)), 0.5)
    await animate_tween2.finished

func animate_spell(spell_animation: SpellAnimation):
    if spell_animation == SpellAnimation.NONE:
        return
    elif spell_animation == SpellAnimation.SCRATCH:
        animation.visible = true
        animation.play("scratch")
        await animation.animation_finished
        animation.visible = false