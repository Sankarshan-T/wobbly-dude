extends Area3D

var bounce_force = 33

func _on_body_entered(body):
	if body.name = "Player":
		var bounce_velocity = Vector3(0, bounce_force, 0)
		body.velocity = bounce_velocity
	
