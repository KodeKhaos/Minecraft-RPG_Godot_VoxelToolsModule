shader_type canvas_item;

uniform float fog_density : hint_range(0, 0.1) = 0.01;
uniform float fog_start : hint_range(0, 100) = 10.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    vec4 scene_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

    // Get depth for fog calculation
    float depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
    depth = PROJECTION_MATRIX[3][2] / (depth * PROJECTION_MATRIX[2][3] - PROJECTION_MATRIX[2][2]);

    // Calculate fog factor based