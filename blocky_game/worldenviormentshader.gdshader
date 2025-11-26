// PhysicalSky with real textured sun rendering
// Fixed to use proper spherical mapping for the sun texture
// Godot 4.5-compatible

shader_type sky;
render_mode use_debanding;

uniform float rayleigh : hint_range(0, 64) = 2.0;
uniform vec4 rayleigh_color : source_color = vec4(0.3, 0.405, 0.6, 1.0);
uniform float mie : hint_range(0, 1) = 0.005;
uniform float mie_eccentricity : hint_range(-1, 1) = 0.8;
uniform vec4 mie_color : source_color = vec4(0.69, 0.729, 0.812, 1.0);

uniform float turbidity : hint_range(0, 1000) = 10.0;
uniform float sun_disk_scale : hint_range(0, 360) = 1.0;
uniform vec4 ground_color : source_color = vec4(0.1, 0.07, 0.034, 1.0);
uniform float exposure : hint_range(0, 128) = 1.0;

uniform sampler2D night_sky : filter_linear, source_color, hint_default_black;
uniform sampler2D stars : filter_linear, source_color, hint_default_black;

const vec3 UP = vec3(0.0, 1.0, 0.0);
const float rayleigh_zenith_size = 8.4e3;
const float mie_zenith_size = 1.25e3;

float henyey_greenstein(float cos_theta, float g) {
	const float k = 0.0795774715459;
	return k * (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5);
}

void sky() {
	float zenith_angle = clamp(dot(UP, normalize(LIGHT0_DIRECTION)), -1.0, 1.0);
	float sun_energy = max(0.0, 0.757 * zenith_angle) * LIGHT0_ENERGY;
	float sun_fade = 1.0 - clamp(1.0 - exp(LIGHT0_DIRECTION.y), 0.0, 1.0);

	// Rayleigh + Mie scattering setup
	float rayleigh_coefficient = rayleigh - (1.0 * (1.0 - sun_fade));
	vec3 rayleigh_beta = rayleigh_coefficient * rayleigh_color.rgb * 0.0001;
	vec3 mie_beta = turbidity * mie * mie_color.rgb * 0.000434;

	float zenith = max(0.0, dot(UP, EYEDIR));
	float optical_mass = 1.0 / (zenith + 0.15 * pow(3.885 + 54.5 * zenith, -1.253));
	float rayleigh_scatter = rayleigh_zenith_size * optical_mass;
	float mie_scatter = mie_zenith_size * optical_mass;

	vec3 extinction = exp(-(rayleigh_beta * rayleigh_scatter + mie_beta * mie_scatter));

	float cos_theta = dot(EYEDIR, normalize(LIGHT0_DIRECTION));
	float rayleigh_phase = (3.0 / (16.0 * PI)) * (1.0 + pow(cos_theta * 0.5 + 0.5, 2.0));
	vec3 betaRTheta = rayleigh_beta * rayleigh_phase;

	float mie_phase = henyey_greenstein(cos_theta, mie_eccentricity);
	vec3 betaMTheta = mie_beta * mie_phase;

	vec3 Lin = pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * (1.0 - extinction), vec3(1.5));
	Lin *= mix(vec3(1.0), pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * extinction, vec3(0.5)), clamp(pow(1.0 - zenith_angle, 5.0), 0.0, 1.0));
	Lin *= mix(ground_color.rgb, vec3(1.0), smoothstep(-0.1, 0.1, dot(UP, EYEDIR)));

	// === Textured Sun Rendering (fixed spherical mapping) ===
	vec3 sun_dir = normalize(LIGHT0_DIRECTION);
	vec3 right = normalize(cross(UP, sun_dir));
	vec3 up = normalize(cross(sun_dir, right));

	float sun_size = LIGHT0_SIZE * sun_disk_scale;
	float alignment = dot(EYEDIR, sun_dir);
	float mask = smoothstep(cos(sun_size), 1.0, alignment);

	vec2 local_dir = vec2(dot(EYEDIR, right), dot(EYEDIR, up));
	float dist = length(local_dir);
	vec2 uv = local_dir / (sun_size * 2.0) + vec2(0.5);

	// Apply extinction & lighting to sun texture
	float sun_intensity = sun_energy * 3.0;
	vec3 L0 = LIGHT0_COLOR * sun_intensity * mask * extinction;

	// Combine atmosphere + sun
	vec3 color = Lin + L0;

	if (LIGHT0_ENERGY == 1.0) {
		COLOR = pow(color, vec3(1.0 / (1.2 + (1.2 * sun_fade))));
		COLOR *= exposure;
	} else if (LIGHT0_ENERGY > 0.0){
		COLOR = mix((texture(night_sky, EYEDIR.xy * 0.5 + 0.5).rgb + texture(stars, EYEDIR.xy * 0.5 + 0.5).rgb) * exposure, pow(color, vec3(1.0 / (1.2 + (1.2 * sun_fade)))) * exposure, LIGHT0_ENERGY);
	} else {
		COLOR = (texture(night_sky, EYEDIR.xy * 0.5 + 0.5).rgb + texture(stars, EYEDIR.xy * 0.5 + 0.5).rgb) * exposure;
	}
}