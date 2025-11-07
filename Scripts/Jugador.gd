extends Area2D

# Variables de movimiento
var velocidad_salto = -600
var gravedad = 1200
var velocidad_y = 0
var esta_vivo = true

# Señal para comunicarse con Principal
signal juego_terminado
signal solicitar_sonido_salto

func _ready():
	# Asegurar que procese input
	set_process_input(true)
	# LÍNEA PARA DETECTAR COLISIONES
	area_entered.connect(_on_area_entered)

# FUNCIÓN PARA DETECTAR COLISIONES CON OBSTÁCULOS
func _on_area_entered(area):
	# Si colisiona con un obstáculo, morir
	if area.is_in_group("obstaculos"):
		morir_por_obstaculo()

func _physics_process(delta):
	if esta_vivo:
		# Aplicar gravedad
		velocidad_y += gravedad * delta
		position.y += velocidad_y * delta
		
		# Limitar caída (evitar que caiga demasiado rápido)
		if velocidad_y > 1500:
			velocidad_y = 1500
			
		# Detectar si sale por la parte SUPERIOR
		if position.y < -50:
			morir_por_techo()
		
		# Detectar si sale de pantalla
		if position.y > 1200:
			terminar_juego()  

func saltar():
	if not esta_vivo:
		return
		
	velocidad_y = velocidad_salto
	
	# Emitir señal para que Principal reproduzca el sonido
	emit_signal("solicitar_sonido_salto")
	
	# FEEDBACK VISUAL - Efecto de salto
	$Jugador.scale = Vector2(1.2, 0.8)  # Se aplasta al saltar
	
	# Timer para regresar a escala normal
	var timer = get_tree().create_timer(0.1)
	timer.connect("timeout", _reset_scale)

func _reset_scale():
	$Jugador.scale = Vector2(1.0, 1.0)

# INPUT TÁCTIL
func _input(event):
	# Detectar toque en cualquier parte de la pantalla
	if event is InputEventScreenTouch:
		if event.pressed and esta_vivo:
			saltar()

# ALTERNATIVA: también responde a clicks de mouse (para testing en PC)
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and esta_vivo:
			saltar()

func terminar_juego():
	if not esta_vivo:
		return
		
	esta_vivo = false
	print("¡Juego Terminado!")
	
	# FEEDBACK VISUAL - Efecto de muerte
	$Jugador.modulate = Color.GRAY  # Se pone gris al morir
	
	# Emitir señal para que Principal lo maneje (CON EL NUEVO NOMBRE)
	emit_signal("juego_terminado")	

# PARA MUERTE POR OBSTÁCULO
func morir_por_obstaculo():
	if not esta_vivo:
		return
	
	esta_vivo = false
	print("¡Chocaste con un obstáculo!")
	
	# Efecto visual diferente para obstáculo
	$Jugador.modulate = Color.RED  # Se pone rojo al chocar
	
	# Emitir señal para que Principal lo maneje
	emit_signal("juego_terminado")

# Muerte por tocar el techo
func morir_por_techo():
	if not esta_vivo:
		return
		
	esta_vivo = false
	print("¡Saliste por el techo!")
	$Jugador.modulate = Color.YELLOW
	emit_signal("juego_terminado")
