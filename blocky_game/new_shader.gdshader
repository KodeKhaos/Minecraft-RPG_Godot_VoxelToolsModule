shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float fog_density : hint_range(0, 0.1) = 0.02;
uniform float fog_start : hint_range(0, 100) = 10.0;

// Match your sky shader uniforms
uniform float rayleigh : hint_range(0, 64) = 2.0;
uniform vec4 rayleigh_color : source_color = vec4(0.3, 0.405, 0.6, 1.0);
uniform vec4 mie_color : source_color = vec4(0.69, 0.729, 0.812, 1.0);
uniform vec4 ground_color : source_color = vec4(0.1, 0.07, 0.034, 1.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    // Get scene color and depth
    vec4 scene_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
    float depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
    depth = PROJECTION_MATRIX[3][2] / (depth * PROJECTION_MATRIX[2][3] - PROJECTION_MATRIX[2][2]);
    
    // Calculate fog amount
    float fog_amount = 1.0 - exp(-fog_density * max(0.0, depth - fog_start));
    fog_amount = clamp(fog_amount, 0.0, 1.0);
    
    // === RECREATE YOUR SKY COLORS FOR FOG ===
    vec3 view_dir = normalize(INV_VIEW_MATRIX * vec4((SCREEN_UV * 2.0 - 1.0), 1.0, 1.0)).xyz;
    
    // Simple sky gradient that matches your shader
    float horizon = smoothstep(-0.1, 0.3, view_dir.y);
    float sky_top = smoothstep(0.3, 1.0, view_dir.y);
    
    vec3 fog_color = ground_color.rgb;
    fog_color = mix(fog_color, rayleigh_color.rgb, horizon);
    fog_color = mix(fog_color, mie_color.rgb, sky_top);
    
    // Apply some atmospheric scattering effect
    fog_color *= (1.0 - fog_amount * 0.3);
    
    // Blend scene with fog
    ALBEDO = mix(scene_color.rgb, fog_color, fog_amount);
    ALPHA = 1.0;
}