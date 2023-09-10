shader_type canvas_item;

uniform float progress: hint_range(0, 1);
uniform int animation;

uniform sampler2D stat_boost_texture;
uniform sampler2D stat_lower_texture;

void fragment() {
    vec4 sampled = texture(TEXTURE, UV);
    if (sampled.a == 0.0) {
        discard;
    }
    if (animation == 1) {
        float stat_boost_y = UV.y + (4.0 * progress);
        while (stat_boost_y > 1.0) {
            stat_boost_y -= 1.0;
        }
        vec2 stat_boost_uv = vec2(UV.x, stat_boost_y);

        vec4 mix_color = texture(stat_boost_texture, stat_boost_uv);

        float mix_value = 1.0 - (abs(0.5 - progress) / 0.5);
        COLOR = mix(sampled, mix_color, mix_value);
    } else if (animation == 2) {
        float stat_boost_y = UV.y + (-4.0 * progress);
        while (stat_boost_y < 0.0) {
            stat_boost_y += 1.0;
        }
        vec2 stat_boost_uv = vec2(UV.x, stat_boost_y);

        vec4 mix_color = texture(stat_lower_texture, stat_boost_uv);

        float mix_value = 1.0 - (abs(0.5 - progress) / 0.5);
        COLOR = mix(sampled, mix_color, mix_value);
    } else if (animation == 3) {
        vec4 mix_color = vec4(145.0 / 255.0, 51.0 / 255.0, 98.0 / 255.0, 1.0);

        float mix_value = 1.0 - (abs(0.5 - progress) / 0.5);
        COLOR = mix(sampled, mix_color, mix_value);
    } else {
        COLOR = sampled;
    }
}
