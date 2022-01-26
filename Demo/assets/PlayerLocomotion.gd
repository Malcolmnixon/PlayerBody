extends Node

# Motion provider priority
export var priority := 99

# Exported locomotion movement parameters
export var max_speed = 3
export var drag_factor = 0.1
export var max_slope := 45.0

# Exported ARVR Controller nodes
export (NodePath) var move_rotate_controller = null
export (NodePath) var move_strafe_controller = null

# Node references
var _move_rotate_controller_node : ARVRController = null
var _move_strafe_controller_node : ARVRController = null

# Horizontal vector (multiply by this to get only the horizontal components
const horizontal := Vector3(1.0, 0.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	if move_rotate_controller:
		_move_rotate_controller_node = get_node(move_rotate_controller)
	if move_strafe_controller:
		_move_strafe_controller_node = get_node(move_strafe_controller)

func physics_movement(delta, player_body):
	# Construct a velocity vector consisting of only the players horizontal velocity
	var horizontal_velocity = player_body.velocity * horizontal

	# If the player is on the ground then give them control
	if player_body.on_ground:
		# Apply the ground drag
		horizontal_velocity *= 1.0 - drag_factor

		# Get movement controls
		var left_right = 0.0
		var forwards_backwards = 0.0

		# If the move/strafe controller is enabled then consume both its move and strafe
		if _move_strafe_controller_node and _move_strafe_controller_node.get_is_active():
			left_right += _move_strafe_controller_node.get_joystick_axis(0)
			forwards_backwards += _move_strafe_controller_node.get_joystick_axis(1)

		# If the move/rotate controller is enabled then consume its move only as the rotation has
		# been handled separately
		if _move_rotate_controller_node and _move_rotate_controller_node.get_is_active():
			forwards_backwards += _move_rotate_controller_node.get_joystick_axis(1)
			forwards_backwards = clamp(forwards_backwards, -1.0, 1.0)

		# Detect if the player is trying to control motion
		if abs(forwards_backwards) > 0.1 or abs(left_right) > 0.1:
			# Get forward and left vectors
			var camera_transform = player_body.camera_node.global_transform
			var dir_forward = (camera_transform.basis.z * horizontal).normalized()
			var dir_right = (camera_transform.basis.x * horizontal).normalized()

			# Ensure total controller speed does not exceed 1.0
			var controller_speed = sqrt(left_right * left_right + forwards_backwards * forwards_backwards)
			if controller_speed > 1.0:
				left_right /= controller_speed
				forwards_backwards /= controller_speed

			# Assign a new horizontal velocity
			horizontal_velocity = (dir_forward * -forwards_backwards + dir_right * left_right) * max_speed * ARVRServer.world_scale

		# Prevent the player from moving up steep slopes
		if player_body.ground_angle > max_slope:
			# Get a vector in the down-hill direction
			var down_direction = player_body.ground_vector * horizontal
			
			# If the velocity has any 'up-hill' direction then subtract it
			var vdot = down_direction.dot(horizontal_velocity)
			if vdot < 0:
				horizontal_velocity -= down_direction * vdot
			
	# Apply horizontal velocity to the players kinematic body
	horizontal_velocity = player_body.kinematic_node.move_and_slide(horizontal_velocity, Vector3(0.0, 1.0, 0.0))

	# Apply the vertical velocity to the players kinematic body
	var vertical_velocity = player_body.velocity * Vector3.UP
	vertical_velocity = player_body.kinematic_node.move_and_slide(vertical_velocity, Vector3(0.0, 1.0, 0.0))
	
	# Update the players velocity
	player_body.velocity.x = horizontal_velocity.x
	player_body.velocity.y = vertical_velocity.y
	player_body.velocity.z = horizontal_velocity.z
