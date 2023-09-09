shader_type canvas_item;

uniform float progress: hint_range(0, 1);
uniform float snap_size = 8.0;
uniform float diamond_size = 16.0;

void fragment() {
    vec2 snapped_uv = vec2(floor((UV.x * 160.0) / snap_size) / (160.0 / snap_size), floor((UV.y * 144.0) / snap_size) / (144.0 / snap_size));
    vec2 centered_uv = vec2(snapped_uv.x - 0.5, snapped_uv.y - 0.5); 
    if (progress == 0.0) {
        discard;
    }
    if (centered_uv.y < 0.0 && atan(centered_uv.y, centered_uv.x) < -3.14 + (3.14 * (1.0 - progress))) {
        discard;
    }
    if (centered_uv.y > 0.0 && atan(-centered_uv.y, centered_uv.x) > -3.14 + (3.14 * (progress))) {
        discard;
    }
}
