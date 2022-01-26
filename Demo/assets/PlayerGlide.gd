extends Node

# Motion provider priority
export var priority := 3

# Exported ARVR Controller nodes
export (NodePath) var left_controller = null
export (NodePath) var right_controller = null

export var glide_detect_distance := 1.0
export var glide_fall_speed := -1.0
export var glide_forward_speed := 10.0
export var slew_rate := 4

# Node references
var _left_controller_node : ARVRController = null
var _right_controller_node : ARVRController = null

# Horizontal vector (multiply by this to get only the horizontal components
const horizontal := Vector3(1.0, 0.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	if left_controller:
		_left_controller_node = get_node(left_controller)
	if right_controller:
		_right_controller_node = get_node(right_controller)

func physics_movement(delta, player_body):
	# Skip if not in the air
	if player_body.on_ground:
		return

	# Skip if we don't have two controllers
	if !_left_controller_node or !_right_controller_node:
		return

	# Skip if either controller is off
	if !_left_controller_node.get_is_active() or !_right_controller_node.get_is_active():
		return

	# Detect if gliding
	var left_position = _left_controller_node.global_transform.origin
	var right_position = _right_controller_node.global_transform.origin
	if left_position.distance_to(right_position) < glide_detect_distance:
		return

	# Adjust the vertical velocity to decelerate to glide_fall_speed
	var vertical_velocity = player_body.velocity.y
	if vertical_velocity < glide_fall_speed:
		vertical_velocity = lerp(vertical_velocity, glide_fall_speed, slew_rate * delta)

	# Adjust the horizontal velocity to forward_speed
	var horizontal_velocity = player_body.velocity * horizontal
	var dir_forward = -(player_body.camera_node.global_transform.basis.z * horizontal).normalized()
	var forward_velocity = dir_forward * glide_forward_speed
	horizontal_velocity = lerp(horizontal_velocity, forward_velocity, slew_rate * delta)

	# Update the players velocity
	player_body.velocity = horizontal_velocity + vertical_velocity * Vector3.UP
