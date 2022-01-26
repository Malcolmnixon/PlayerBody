extends Node

# Motion provider priority
export var priority := 2

# Gravity settings
export var gravity := -9.8

func physics_movement(delta, player_body):
	# Update the players vertical velocity based on gravity
	player_body.velocity.y += gravity * delta
