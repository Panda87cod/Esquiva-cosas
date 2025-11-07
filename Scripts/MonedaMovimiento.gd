extends Area2D

var velocidad = 250

func _ready():
	pass

func _physics_process(delta):
	# Mover hacia la izquierda como los obstáculos
	position.x -= velocidad * delta
	
	# Eliminar si sale de pantalla
	if position.x < -100:
		queue_free()
