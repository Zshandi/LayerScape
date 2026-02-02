shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.1, 0.0);

void fragment() {
    vec2 effective_scroll;
    
    effective_scroll = scroll_speed;

    vec2 offset = effective_scroll * TIME;
    
    vec2 scrolled_uv = UV + offset;
    
    COLOR = texture(TEXTURE, scrolled_uv);
}