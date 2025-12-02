# Obstaculo.gd
extends Area2D

var velocidad = 300

func _ready():
	add_to_group("obstaculos")

func _physics_process(delta):
	position.x -= velocidad * delta
	
	# Si sale de pantalla, eliminarse
	if position.x < -100:
		queue_free()

# Nuevo método para ajustar velocidad desde Principal
func set_velocidad(nueva_velocidad):
	velocidad = nueva_velocidad
