shader_type canvas_item;

uniform float progress: hint_range(0, 1);
uniform float snap_size = 8.0;
uniform float diamond_size = 16.0;

void fragment() {
    vec2 snapped_uv = vec2(floor((UV.x * 160.0) / snap_size) / (160.0 / snap_size), floor((UV.y * 144.0) / snap_size) / (144.0 / snap_size));
    vec2 centered_uv = vec2(snapped_uv.x - 0.5, snapped_uv.y - 0.5); 
    float x_fraction = fract(FRAGCOORD.x / diamond_size);
    float y_fraction = fract(FRAGCOORD.y / diamond_size);
    float x_dist = abs(x_fraction - 0.5);
    float y_dist = abs(y_fraction - 0.5);
    if (x_dist + y_dist + (0.5 - abs(centered_uv.x)) + (0.5 - abs(centered_uv.y)) > progress * 2.0) {
    // if (progress != 1.0 && atan(centered_uv.y, centered_uv.x) > -3.14 + (6.28 * progress)) {
        discard;
    }
}
