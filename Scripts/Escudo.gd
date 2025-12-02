# Escudo.gd
extends Area2D

var velocidad = 280  # Similar velocidad a obstáculos

func _ready():
	add_to_group("escudos")
	
	# Crear sprite del escudo (diamante azul)
	var sprite = ColorRect.new()
	sprite.color = Color(0.2, 0.5, 1.0)  # Azul brillante
	sprite.size = Vector2(40, 40)
	sprite.position = Vector2(-20, -20)

	# Efecto de rotación continua
	var tween_rotacion = create_tween()
	tween_rotacion.tween_property(sprite, "rotation_degrees", 360, 2.0)
	tween_rotacion.set_loops()

	# Efecto de pulso (cambiar tamaño)
	var tween_escala = create_tween()
	tween_escala.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
	tween_escala.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)
	tween_escala.set_loops()

	add_child(sprite)
	
	# Colisión circular
	var colision = CollisionShape2D.new()
	colision.shape = CircleShape2D.new()
	colision.shape.radius = 20
	add_child(colision)

func _physics_process(delta):
	# Movimiento igual que obstáculos
	position.x -= velocidad * delta
	
	# Eliminar si sale de pantalla
	if position.x < -100:
		queue_free()
		# Notificar a Principal que este escudo ya no existe
		if get_parent().has_method("_on_escudo_salió_de_pantalla"):
			get_parent()._on_escudo_salió_de_pantalla(self)

func set_velocidad(nueva_velocidad):
	velocidad = nueva_velocidad
