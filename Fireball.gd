extends Area2D

var speed = 2000

func _physics_process(delta):
	global_position.x += speed * delta


func _on_area_entered(area):
	if area.name == "Balloon":
		queue_free()
	if area.name == "Tree":
		queue_free()
	if area.name == "Castle":
		queue_free()
	if area.name == "Rock":
		queue_free()
