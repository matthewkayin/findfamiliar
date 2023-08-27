extends Node2D
class_name BattleAnimator

@onready var player_party = get_node("/root/player_party")
@onready var enemy_party = get_node("/root/enemy_party")

@onready var player_sprite = get_node("../player_sprite")
@onready var enemy_sprite = get_node("../enemy_sprite")
@onready var player_healthbar = get_node("../player_healthbar")
@onready var enemy_healthbar = get_node("../enemy_healthbar")
@onready var player_animation = get_node("../player_sprite/animation")
@onready var enemy_animation = get_node("../enemy_sprite/animation")

enum SpellAnimation {
    NONE,
    SCRATCH
}

func _ready():
    player_sprite.texture = null
    enemy_sprite.texture = null
    player_animation.visible = false
    enemy_animation.visible = false

func animate_enter():
    enemy_sprite.texture = load("res://battle/sprites/front/" + enemy_party.familiars[0].species.name.replace(" ", "-").to_lower() + ".png")
    enemy_sprite.position = Vector2(-64, 64) 
    enemy_sprite.visible = true

    player_sprite.texture = load("res://battle/sprites/back/player.png")
    player_sprite.position = Vector2(320, 178)
    player_sprite.visible = true

    var enemy_tween = get_tree().create_tween()
    enemy_tween.tween_property(enemy_sprite, "position", Vector2(256, 64), 2.0)
    var player_tween = get_tree().create_tween()
    player_tween.tween_property(player_sprite, "position", Vector2(56, 178), 2.0)
    await player_tween.finished

    visible = true

func animate_player_exit():
    var animate_tween = get_tree().create_tween()

    animate_tween.tween_property(player_sprite, "position", Vector2(-56, 192), 0.5)
    await animate_tween.finished

func animate_enemy_exit():
    var animate_tween = get_tree().create_tween()

    animate_tween.tween_property(enemy_sprite, "position", Vector2(376, 64), 0.5)
    await animate_tween.finished

func animate_summon(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var healthbar = player_healthbar if who == Battle.ActionActor.PLAYER else enemy_healthbar
    var face = "back" if who == Battle.ActionActor.PLAYER else "front"
    var party = player_party if who == Battle.ActionActor.PLAYER else enemy_party
    var species_sprite = load("res://battle/sprites/" + face + "/" + party.familiars[0].species.name.replace(" ", "-").to_lower() + ".png")

    sprite.position = Vector2(56, 184) if who == Battle.ActionActor.PLAYER else Vector2(256, 64)
    sprite.texture = null
    sprite.region_enabled = false
    animation.visible = true
    animation.play("summon")
    await animation.animation_finished
    animation.visible = false
    sprite.texture = species_sprite
    healthbar.open()

func animate_unsummon(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var healthbar = player_healthbar if who == Battle.ActionActor.PLAYER else enemy_healthbar

    sprite.texture = null
    animation.visible = true
    animation.play("unsummon")
    await animation.animation_finished
    animation.visible = false
    healthbar.visible = false

func animate_hurt(who: Battle.ActionActor, effectiveness: float):
    var speed_mod: float = 1.0
    if effectiveness == 2.0:
        speed_mod = 0.75
    elif effectiveness == 0.5:
        speed_mod = 1.25

    if who == Battle.ActionActor.ENEMY:
        for i in range(0, 3):
            enemy_sprite.visible = false
            var animate_tween = get_tree().create_tween()
            animate_tween.tween_interval(0.1 * speed_mod)
            await animate_tween.finished
            enemy_sprite.visible = true
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

func animate_faint(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite

    sprite.region_rect.size = sprite.get_rect().size
    sprite.region_enabled = true

    var animate_tween = get_tree().create_tween()
    animate_tween.tween_property(sprite, "position", sprite.position + Vector2(0, sprite.region_rect.size.y), 0.5)
    var animate_tween2 = get_tree().create_tween()
    animate_tween2.tween_property(sprite, "region_rect", Rect2(sprite.region_rect.position, Vector2(sprite.region_rect.size.x, 0)), 0.5)
    await animate_tween2.finished

func animate_spell(who: Battle.ActionActor, spell_animation: SpellAnimation):
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    if spell_animation == SpellAnimation.SCRATCH:
        defender_animation.visible = true
        defender_animation.play("scratch")
        await defender_animation.animation_finished
        defender_animation.visible = false
