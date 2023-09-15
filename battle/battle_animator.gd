extends Node2D
class_name BattleAnimator

signal process_finished

@onready var flame_effect_texture = preload("res://battle/effects/flame.png")
@onready var water_effect_texture = preload("res://battle/effects/water.png")
@onready var leaf_effect_texture = preload("res://battle/effects/leaf.png")

@onready var player_party = get_node("/root/player_party")
@onready var enemy_party = get_node("/root/enemy_party")

@onready var player_sprite = get_node("../player_sprite")
@onready var enemy_sprite = get_node("../enemy_sprite")
@onready var player_healthbar = get_node("../player_healthbar")
@onready var enemy_healthbar = get_node("../enemy_healthbar")
@onready var player_animation = get_node("../player_sprite/animation")
@onready var enemy_animation = get_node("../enemy_sprite/animation")

enum SpriteEffectAnim {
    STAT_RAISE = 1,
    STAT_LOWER = 2,
    POISON = 3,
    BURNED = 4
}

var process_state = ""

var stat_effect_sprite = null
var stat_effect_progress

func _ready():
    player_sprite.texture = null
    enemy_sprite.texture = null
    player_animation.visible = false
    enemy_animation.visible = false

func _process(delta):
    if process_state == "":
        return
    if not has_method("process_" + process_state):
        return
    call("process_" + process_state, delta)

func animate_enter(is_duel: bool):
    enemy_sprite.texture = enemy_party.enemy_witch_sprite if is_duel else load("res://battle/sprites/front/" + enemy_party.get_familiar(0).species.name.replace(" ", "-").to_lower() + ".png")
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

func animate_enemy_reenter():
    var animate_tween = get_tree().create_tween()

    enemy_sprite.texture = enemy_party.enemy_witch_sprite
    enemy_sprite.region_enabled = false
    enemy_sprite.position = Vector2(320, 64)
    animate_tween.tween_property(enemy_sprite, "position", Vector2(256, 64), 0.5)
    await animate_tween.finished

func animate_summon(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var healthbar = player_healthbar if who == Battle.ActionActor.PLAYER else enemy_healthbar
    var face = "back" if who == Battle.ActionActor.PLAYER else "front"
    var party = player_party if who == Battle.ActionActor.PLAYER else enemy_party
    var species_sprite = load("res://battle/sprites/" + face + "/" + party.get_familiar(0).species.name.replace(" ", "-").to_lower() + ".png")

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

func animate_sprite_effect(sprite, anim_num: int):
    stat_effect_sprite = sprite
    stat_effect_sprite.material.set_shader_parameter("progress", 0.0)
    stat_effect_sprite.material.set_shader_parameter("animation", anim_num)
    stat_effect_progress = 0.0
    process_state = "sprite_effect"
    await process_finished
    stat_effect_sprite.material.set_shader_parameter("animation", 0)
    stat_effect_sprite = null
    process_state = ""

func is_animating_sprite_effect() -> bool:
    return stat_effect_sprite != null

func process_sprite_effect(delta):
    stat_effect_progress = min(stat_effect_progress + delta, 1.0)
    stat_effect_sprite.material.set_shader_parameter("progress", stat_effect_progress)
    if stat_effect_progress == 1.0:
        process_state = ""
        emit_signal("process_finished")

func animate_condition(who: Battle.ActionActor, condition: Condition.Type):
    var condition_name = Condition.Type.keys()[condition].to_lower().replace(" ", "_")
    if not self.has_method("animate_" + condition_name):
        return
    await call("animate_" + condition_name, who)

func animate_poisoned(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite

    var shake_tween = get_tree().create_tween()
    var sprite_origin = sprite.position
    shake_tween.tween_property(sprite, "position", sprite_origin + Vector2(-2, 0), 0.05)
    for i in range(0, 8):
        var side = Vector2(2, 0) if i % 2 == 0 else Vector2(-2, 0)
        shake_tween.tween_property(sprite, "position", sprite_origin + side, 0.1)
    shake_tween.tween_property(sprite, "position", sprite_origin, 0.05)
    animate_sprite_effect(sprite, SpriteEffectAnim.POISON)
    await shake_tween.finished

func animate_burned(who: Battle.ActionActor):
    var sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var start_position = player_sprite.position if who == Battle.ActionActor.PLAYER else enemy_sprite.position
    start_position += Vector2(0, 32)

    var fire_sprites = []
    animate_sprite_effect(sprite, SpriteEffectAnim.BURNED)
    for i in range(0, 5):
        var fire_sprite = Sprite2D.new()
        fire_sprite.texture = flame_effect_texture
        fire_sprite.hframes = 2
        fire_sprite.scale = Vector2(1.5, 1.5)
        var offset = Vector2(6, 0) if i % 2 == 0 else Vector2(-6, 0)
        fire_sprite.position = start_position + offset
        get_parent().add_child(fire_sprite)

        var fire_tween = get_tree().create_tween().set_parallel(true)
        fire_tween.tween_property(fire_sprite, "position", start_position + Vector2(0, -48), 0.5)
        fire_tween.tween_property(fire_sprite, "scale", Vector2(0, 0), 0.5)
        if i == 4:
            await fire_tween.finished
        else:
            var delay_tween = get_tree().create_tween()
            delay_tween.tween_interval(0.1)
            await delay_tween.finished

    for fire_sprite in fire_sprites:
        fire_sprite.queue_free()

func animate_spell(who: Battle.ActionActor, spell: Spell):
    var spell_name = spell.name.to_lower().replace(" ", "_")
    if not self.has_method("animate_" + spell_name):
        return
    await call("animate_" + spell_name, who)

func animate_scratch(who: Battle.ActionActor):
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    defender_animation.visible = true
    defender_animation.play("scratch")
    await defender_animation.animation_finished
    defender_animation.visible = false

func animate_growl(who: Battle.ActionActor):
    var attacker_animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var defender_sprite = enemy_sprite if who == Battle.ActionActor.PLAYER else player_sprite

    attacker_animation.visible = true
    attacker_animation.flip_h = who == Battle.ActionActor.ENEMY
    attacker_animation.play("growl")
    await attacker_animation.animation_finished
    attacker_animation.visible = false
    attacker_animation.flip_h = false

    await animate_sprite_effect(defender_sprite, SpriteEffectAnim.STAT_LOWER)

func animate_leer(who: Battle.ActionActor):
    var attacker_animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var defender_sprite = enemy_sprite if who == Battle.ActionActor.PLAYER else player_sprite

    attacker_animation.visible = true
    attacker_animation.flip_h = who == Battle.ActionActor.ENEMY
    attacker_animation.play("leer")
    await attacker_animation.animation_finished
    attacker_animation.visible = false
    attacker_animation.flip_h = false

    await animate_sprite_effect(defender_sprite, SpriteEffectAnim.STAT_LOWER)

func animate_bad_luck(who: Battle.ActionActor):
    var attacker_animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var defender_sprite = enemy_sprite if who == Battle.ActionActor.PLAYER else player_sprite

    attacker_animation.visible = true
    attacker_animation.flip_h = who == Battle.ActionActor.ENEMY
    attacker_animation.play("bad_luck")
    await attacker_animation.animation_finished
    attacker_animation.visible = false
    attacker_animation.flip_h = false

    await animate_sprite_effect(defender_sprite, SpriteEffectAnim.STAT_LOWER)

func animate_slam(who: Battle.ActionActor):
    var attacker_sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    var attacker_movement = Vector2(16, 0) if who == Battle.ActionActor.PLAYER else Vector2(-16, 0)
    var attack_tween = get_tree().create_tween()
    attack_tween.tween_property(attacker_sprite, "position", attacker_sprite.position + attacker_movement, 0.1)
    await attack_tween.finished
    
    defender_animation.visible = true
    defender_animation.play("tackle_hit")

    var attack_tween2 = get_tree().create_tween()
    attack_tween2.tween_property(attacker_sprite, "position", attacker_sprite.position - attacker_movement, 0.1)
    attack_tween2.tween_interval(0.1)
    await attack_tween2.finished

    defender_animation.visible = false

func animate_rush(who: Battle.ActionActor):
    var attacker_sprite = player_sprite if who == Battle.ActionActor.PLAYER else enemy_sprite
    var attacker_animation = player_animation if who == Battle.ActionActor.PLAYER else enemy_animation
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    var attacker_sprite_texture = attacker_sprite.texture
    attacker_sprite.texture = null
    attacker_animation.visible = true
    attacker_animation.play("rush")
    await attacker_animation.animation_finished
    attacker_animation.visible = false

    defender_animation.visible = true
    defender_animation.play("tackle_hit")
    var delay_tween = get_tree().create_tween()
    delay_tween.tween_interval(0.15)
    await delay_tween.finished

    defender_animation.visible = false
    attacker_sprite.texture = attacker_sprite_texture

func animate_cat_claw(who: Battle.ActionActor):
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    defender_animation.visible = true
    defender_animation.play("cat_claw")
    await defender_animation.animation_finished
    defender_animation.visible = false

func animate_flare(who: Battle.ActionActor):
    var fire_sprite_begin_position = player_sprite.position + Vector2(20, -20 - flame_effect_texture.get_height()) if who == Battle.ActionActor.PLAYER else enemy_sprite.position + Vector2(-20, 20 + flame_effect_texture.get_height())
    var fire_sprite_end_position = enemy_sprite.position + Vector2(0, 56 - (flame_effect_texture.get_height() / 4.0)) if who == Battle.ActionActor.PLAYER else player_sprite.position + Vector2(0, 48 - (flame_effect_texture.get_height() / 4.0))
    fire_sprite_end_position.x -= flame_effect_texture.get_width()

    var fire_sprites = []
    for i in range(0, 3):
        var fire_sprite = Sprite2D.new()
        fire_sprite.texture = flame_effect_texture
        fire_sprite.hframes = 2
        fire_sprite.frame = 0
        get_parent().add_child(fire_sprite)
        fire_sprites.append(fire_sprite)

        fire_sprite.position = fire_sprite_begin_position
        var fire_tween = get_tree().create_tween()
        fire_tween.tween_property(fire_sprite, "position", fire_sprite_end_position, 0.5)
        fire_sprite_end_position.x += flame_effect_texture.get_width()
        if i == 2:
            await fire_tween.finished
        else:
            var delay_tween = get_tree().create_tween()
            delay_tween.tween_interval(0.1)
            await delay_tween.finished

    for sprite in fire_sprites:
        sprite.scale = Vector2(2.0, 2.0)
    for j in range(0, 4):
        var fire_tween = get_tree().create_tween()
        fire_tween.tween_interval(0.2)
        await fire_tween.finished
        for sprite in fire_sprites:
            sprite.frame = (sprite.frame + 1) % 2

    var delay_tween = get_tree().create_tween()
    delay_tween.tween_interval(0.2)
    await delay_tween.finished

    for sprite in fire_sprites:
        sprite.visible = false
        sprite.queue_free()

var water_sprite_begin_position: Vector2 
var water_sprite_end_position: Vector2 
var water_sprites = []

func animate_water_jet(who: Battle.ActionActor):
    water_sprite_begin_position = player_sprite.position + Vector2(20, -20 - water_effect_texture.get_height()) if who == Battle.ActionActor.PLAYER else enemy_sprite.position + Vector2(-20, 20 + water_effect_texture.get_height())
    water_sprite_end_position = enemy_sprite.position if who == Battle.ActionActor.PLAYER else player_sprite.position

    water_sprites = []
    process_state = "water_jet"
    for i in range(0, 5):
        var water_sprite = Sprite2D.new()
        water_sprite.texture = water_effect_texture
        get_parent().add_child(water_sprite)
        water_sprites.append({
            "sprite": water_sprite,
            "progress": 0.0 
        })

        water_sprite.position = water_sprite_begin_position
        water_sprite.hframes = 2
        water_sprite.flip_h = who == Battle.ActionActor.ENEMY
        water_sprite.flip_v = who == Battle.ActionActor.ENEMY
        water_sprite.scale = Vector2(2.0, 2.0)

        var delay_tween = get_tree().create_tween()
        delay_tween.tween_interval(0.1)
        await delay_tween.finished

    if water_sprites.size() != 0:
        await process_finished
    
func process_water_jet(delta):
    var to_remove = []
    for i in range(0, water_sprites.size()):
        var sprite = water_sprites[i]
        sprite.progress += delta * 1.5
        if sprite.progress >= 1.3:
            to_remove.append(i)
            continue
        if sprite.progress >= 1.0:
            sprite.sprite.frame = 1
            sprite.sprite.flip_h = i % 2 == 1
            sprite.sprite.flip_v = false
            sprite.sprite.position = water_sprite_end_position + (Vector2(-0.2 if sprite.sprite.flip_h else 0.2, 1) * (((sprite.progress - 1.0) / 0.3) * 8))
            continue
        sprite.sprite.position = water_sprite_begin_position + ((water_sprite_end_position - water_sprite_begin_position) * sprite.progress)
        sprite.sprite.position += Vector2(0, -1) * 30.0 * sin(sprite.progress * 3.14)
    for index in to_remove:
        var sprite = water_sprites[index]
        sprite.sprite.position = water_sprite_end_position
        sprite.sprite.visible = false
        sprite.sprite.queue_free()
        water_sprites.remove_at(index)
    if water_sprites.size() == 0:
        emit_signal("process_finished")
        process_state = ""

func animate_leaf_blade(who: Battle.ActionActor):
    var leaf_begin_position = player_sprite.position + Vector2(-20, 48) if who == Battle.ActionActor.PLAYER else enemy_sprite.position + Vector2(20, 48)
    var leaf_pos2 = player_sprite.position + Vector2(20, 0) if who == Battle.ActionActor.PLAYER else enemy_sprite.position + Vector2(-20, 0)
    var leaf_pos3 = player_sprite.position + Vector2(-20, -48) if who == Battle.ActionActor.PLAYER else enemy_sprite.position + Vector2(20, -48)
    var leaf_pos4 = enemy_sprite.position + Vector2(-40, 0) if who == Battle.ActionActor.PLAYER else player_sprite.position + Vector2(48, 0)
    var defender_animation = enemy_animation if who == Battle.ActionActor.PLAYER else player_animation

    var leaf_sprite = Sprite2D.new()
    leaf_sprite.texture = leaf_effect_texture
    leaf_sprite.flip_h = who == Battle.ActionActor.ENEMY
    leaf_sprite.hframes = 2
    get_parent().add_child(leaf_sprite)
    leaf_sprite.position = leaf_begin_position

    var speed = 0.4

    var leaf_x_tween = get_tree().create_tween().set_parallel(true)
    leaf_x_tween.tween_property(leaf_sprite, "position:x", leaf_pos2.x, speed)
    leaf_x_tween.tween_property(leaf_sprite, "position:y", leaf_pos2.y, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    await leaf_x_tween.finished

    leaf_sprite.flip_h = not leaf_sprite.flip_h
    var leaf_x_tween2 = get_tree().create_tween().set_parallel(true)
    leaf_x_tween2.tween_property(leaf_sprite, "position:x", leaf_pos3.x, speed)
    leaf_x_tween2.tween_property(leaf_sprite, "position:y", leaf_pos3.y, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    await leaf_x_tween2.finished

    leaf_sprite.flip_h = not leaf_sprite.flip_h
    leaf_sprite.flip_v = leaf_sprite.flip_h
    leaf_sprite.frame = 1
    var leaf_tween = get_tree().create_tween()
    leaf_tween.tween_property(leaf_sprite, "position", leaf_pos4, 0.3)
    await leaf_tween.finished

    leaf_sprite.visible = false
    leaf_sprite.queue_free()

    defender_animation.flip_h = who == Battle.ActionActor.ENEMY
    defender_animation.flip_v = who == Battle.ActionActor.ENEMY
    defender_animation.visible = true
    defender_animation.play("leaf_cut")
    await defender_animation.animation_finished
    defender_animation.visible = false
    defender_animation.flip_h = false
    defender_animation.flip_v = false

