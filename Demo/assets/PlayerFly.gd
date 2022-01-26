extends Node

# enum our buttons, should find a way to put this more central
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

# Motion provider priority
export var priority := 1

# Exported ARVR Controller nodes
export (NodePath) var fly_controller = null

# Export fly button
export (Buttons) var fly_button_id = Buttons.VR_TRIGGER

# Fly speed
export var fly_speed := 5.0

# Node references
var _fly_controller_node : ARVRController = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	if fly_controller:
		_fly_controller_node = get_node(fly_controller)

func physics_movement(delta, player_body):
	# Skip if the fly controller isn't active
	if !_fly_controller_node or !_fly_controller_node.get_is_active():
		return

	# Skip if the fly button isn't pressed
	if !_fly_controller_node.is_button_pressed(fly_button_id):
		return

	# Calculate the velocity based on the controllers direction
	var velocity = -_fly_controller_node.global_transform.basis.z.normalized() * fly_speed * ARVRServer.world_scale

	# Move the player kinematic body in the given direction
	player_body.velocity = player_body.kinematic_node.move_and_slide(velocity)

	# Return true indicating no other motion providers should execute
	return true
