shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (texture(TEXTURE, UV) == vec4(1,1,1,1))
	{
		// grab the screen behind this canvas item
		
		// invert the colors
		col.rgb = 1.0 - col.rgb;
		
		COLOR = col;
		}
	else
		COLOR = vec4(0,0,0,0);
}
