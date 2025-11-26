extends DirectionalLight3D

@export var world_environment : WorldEnvironment

@onready var mp := get_tree().get_multiplayer()
var direction := 0.0

# --- Tweakables ---
var min_energy := 0.0
var max_energy := 1.0
var energy_falloff := 1.2
var energy_start_angle := 80.0   # starts dimming here
var energy_end_angle := 89.0     # fully dark here

var horizon_color := Color(1.0, 0.6, 0.3)
var zenith_color := Color(1.0, 1.0, 1.0)
var color_falloff := 1.0
var color_start_angle := 75.0    # starts turning orange here
var color_end_angle := 80.0      # fully orange here

var turn_speed_quantifier := 3.6 # 0.4 makes 15 minutes

func _ready() -> void:
	rotation_degrees = Vector3(-64.4, -175.7, 0.0)

func _process(delta: float) -> void:
	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer():
		if mp.is_server():
			# rotate sun
			rotate_z(deg_to_rad(delta * turn_speed_quantifier))
			direction += delta * turn_speed_quantifier
			if direction >= 360.0:
				direction = 0
			rpc("rpc_update_sun_direction", direction)
	else:
		# rotate sun
		rotate_z(deg_to_rad(delta * turn_speed_quantifier))
		direction += delta * turn_speed_quantifier
		if direction >= 360.0:
			direction = 0
	
	# Map direction to [-180, 180] for symmetrical sunrise/sunset behavior
	var normalized_dir = fposmod(direction + 180.0, 360.0) - 180.0
	var abs_dir = abs(normalized_dir)
	
	# --- Light energy fade ---
	var energy_factor = clamp((energy_end_angle - abs_dir) / (energy_end_angle - energy_start_angle), 0.0, 1.0)
	light_energy = lerp(min_energy, max_energy, pow(energy_factor, energy_falloff))
	
	# --- Light color transition ---
	var color_factor = clamp((color_end_angle - abs_dir) / (color_end_angle - color_start_angle), 0.0, 1.0)
	light_color = lerp(horizon_color, zenith_color, pow(color_factor, color_falloff))

	# --- Environment tint (matches the sun color) ---
	
	var sky_color : Color = lerp(world_environment.environment.sky.sky_material.get("shader_parameter/rayleigh_color"), Color(0.35,0.45,0.5), 0.8)

	world_environment.environment.sky.sky_material.set("shader_parameter/mie_color", horizon_color) # light_color
	world_environment.environment.fog_light_color = sky_color


func set_direction(value: float) -> void:
	direction = value
	if not mp.is_server():
		rotation_degrees.z = value  # instantly update rotation on clients

func get_direction() -> float:
	return direction

@rpc("any_peer")
func rpc_update_sun_direction(new_dir: float) -> void:
	direction = new_dir
	rotation_degrees.z = new_dir
