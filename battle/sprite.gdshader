shader_type canvas_item;

uniform float progress: hint_range(0, 1);
uniform int animation: hint_range(0, 2);

uniform sampler2D stat_boost_texture;
uniform sampler2D stat_lower_texture;

void fragment() {
    vec4 sampled = texture(TEXTURE, UV);
    if (sampled.a == 0.0) {
        discard;
    }
    if (animation == 0) {
        COLOR = sampled;
    }

    float stat_boost_y;
    if (animation == 1) {
        stat_boost_y = UV.y + (6.0 * progress);
        while (stat_boost_y > 1.0) {
            stat_boost_y -= 1.0;
        }
    } else {
        stat_boost_y = UV.y + (-6.0 * progress);
        while (stat_boost_y < 0.0) {
            stat_boost_y += 1.0;
        }
    }
    vec2 stat_boost_uv = vec2(UV.x, stat_boost_y);

    vec4 stat_mod_sampled;
    if (animation == 1) {
        stat_mod_sampled = texture(stat_boost_texture, stat_boost_uv);
    } else {
        stat_mod_sampled = texture(stat_lower_texture, stat_boost_uv);
    }
    float mix_value = 1.0 - (abs(0.5 - progress) / 0.5);
    COLOR = mix(sampled, stat_mod_sampled, mix_value);
}
