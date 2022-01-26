extends Node

# Motion provider priority
export var priority := 0

# Exported locomption rotation parameters
export var smooth_rotation := false
export var smooth_turn_speed := 2.0
export var step_turn_delay := 0.2
export var step_turn_angle := 20.0

# Exported ARVR Controller nodes
export (NodePath) var rotate_controller = null

# Node references
var _rotate_controller_node : ARVRController = null

# Step turn state
var _turn_step = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	if rotate_controller:
		_rotate_controller_node = get_node(rotate_controller)

func physics_movement(delta, player_body):
	# Skip if no active rotation controller
	if !_rotate_controller_node or !_rotate_controller_node.get_is_active():
		return;

	# Get the left/right rotation input
	var left_right = _rotate_controller_node.get_joystick_axis(0)
	if abs(left_right) <= 0.1:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation		
	if smooth_rotation:
		_rotate_player(player_body, smooth_turn_speed * delta * left_right)
		return

	# Clear step accumulator on direction change (opposite signs)
	if left_right * _turn_step < 0.0:
		_turn_step = 0.0

	# Integrate the control into the step accumulator
	_turn_step += left_right * delta
	
	# Calculate how many steps to perform (if any)
	var steps = int(_turn_step / step_turn_delay)
	if steps != 0:
		# Apply the rotation
		var step_angle = steps * step_turn_angle
		_rotate_player(player_body, step_angle * PI / 180.0)
		
		# Subtract the rotation from the accumulator
		_turn_step -= step_angle

# Rotate the origin node around the camera
func _rotate_player(player_body, angle):
	var t1 = Transform()
	var t2 = Transform()
	var rot = Transform()

	t1.origin = -player_body.camera_node.transform.origin
	t2.origin = player_body.camera_node.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	player_body.origin_node.transform = (player_body.origin_node.transform * t2 * rot * t1).orthonormalized()
