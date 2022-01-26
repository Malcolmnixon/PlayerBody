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
export var priority := 4

# Exported ARVR Controller nodes
export (NodePath) var jump_controller = null

# Export jump button
export (Buttons) var jump_button_id = Buttons.VR_TRIGGER

# Jump velocity
export var jump_velocity := 3.0

# Node references
var _jump_controller_node : ARVRController = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	if jump_controller:
		_jump_controller_node = get_node(jump_controller)

func physics_movement(delta, player_body):
	# Skip if the player isn't on the ground
	if !player_body.on_ground:
		return

	# Skip if the jump controller isn't active
	if !_jump_controller_node or !_jump_controller_node.get_is_active():
		return

	# Skip if the jump button isn't pressed
	if !_jump_controller_node.is_button_pressed(jump_button_id):
		return

	# Perform the jump
	player_body.velocity.y = jump_velocity * ARVRServer.world_scale
