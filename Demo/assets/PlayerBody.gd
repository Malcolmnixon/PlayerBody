extends Node

# State of the ground under the player
enum GROUND_STATE {
	 AIR,		# No ground under player
	 GROUND,	# Usable ground under player
	 SLOPE		# Steep slope under player
}

# Exported body parameters
export var enabled := true setget set_enabled, get_enabled
export var player_radius := 0.4

# Exported ARVR nodes
export (NodePath) var origin = null
export (NodePath) var camera = null

# Node references
var origin_node: ARVROrigin = null
var camera_node: ARVRCamera = null
var kinematic_node: KinematicBody = null
var collision_node: CollisionShape = null

# Public player state
var velocity := Vector3.ZERO
var on_ground := true
var ground_vector := Vector3.UP
var ground_angle := 0.0

# Movement providers
var _movement_providers := Array()

class SortProviderByPriority:
	static func sort_by_priority(a, b):
		return true if a.priority < b.priority else false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the origin node
	if origin:
		origin_node = get_node(origin)
	else:
		origin_node = get_node("..")
	
	# Get the camera node
	if camera:
		camera_node = get_node(camera)
	else:
		camera_node = origin_node.get_node("ARVRCamera")

	# Get the body nodes
	kinematic_node = $KinematicBody
	collision_node = $KinematicBody/CollisionShape
	
	# Get the movement providers ordered by priority
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(SortProviderByPriority, "sort_by_priority")

func set_enabled(new_value):
	enabled = new_value
	
	# Update collision_shape
	if collision_node:
		collision_node.disabled = !enabled
	
	# Update physics processing
	if enabled:
		set_physics_process(true)

func get_enabled():
	return enabled

func _physics_process(delta):
	# Detect if the player cannot perform physics processing
	if !origin_node or !camera_node or !enabled:
		set_physics_process(false)
		return

	# Calculate the player height based on the origin and camera position
	var player_height = camera_node.transform.origin.y + player_radius
	if player_height < player_radius:
		player_height = player_radius

	# Adjust the collision shape to match the player geometry
	collision_node.shape.radius = player_radius
	collision_node.shape.height = player_height - (player_radius * 2.0)
	collision_node.transform.origin.y = (player_height / 2.0)

	# Center the kinematic body on the ground under the camera
	var curr_transform = kinematic_node.global_transform
	var camera_transform = camera_node.global_transform
	curr_transform.origin = camera_transform.origin
	curr_transform.origin.y = origin_node.global_transform.origin.y

	# The camera/eyes are towards the front of the body, so move the body back slightly
	var forward_dir = -camera_transform.basis.z
	forward_dir.y = 0.0
	if forward_dir.length() > 0.01:
		curr_transform.origin += forward_dir.normalized() * -0.66 * player_radius

	# Set the body position
	kinematic_node.global_transform = curr_transform

	# Update the ground information
	var ground_collision = $KinematicBody.move_and_collide(Vector3(0.0, -0.05, 0.0), true, true, true)
	if !ground_collision:
		on_ground = false
		ground_vector = Vector3.UP
		ground_angle = 0.0
	else:
		on_ground = true
		ground_vector = ground_collision.normal
		ground_angle = ground_collision.get_angle() * 57.2957795131
		
		# Detect if we're on a wall
		if ground_angle > 85:
			on_ground = false

	# Run the movement providers in order. The providers can:
	# - Move the kinematic node around (to move the player)
	# - Rotate the ARVROrigin around the camera (to rotate the player)
	# - Read and modify the player velocity
	for p in _movement_providers:
		if p.physics_movement(delta, self):
			break

	# Calculate how far the kinematic node has been displaced
	var movement = (kinematic_node.global_transform.origin - curr_transform.origin)

	# Update the origin by the same displacement
	origin_node.global_transform.origin += movement
