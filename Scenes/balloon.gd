extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= get_parent().speed / 3

func _on_area_entered(area):
	if area.name == "Fireball":
		queue_free()
