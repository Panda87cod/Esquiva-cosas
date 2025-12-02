# Jugador.gd
extends Area2D

# Variables de movimiento
var velocidad_salto = -600
var gravedad = 1200
var velocidad_y = 0
var esta_vivo = true

# Escudo del jugador
var escudo_visual = null
var escudo_activo_local = false

# Señal para comunicarse con Principal
signal juego_terminado
signal solicitar_sonido_salto

func _ready():
	# Asegurar que procese input
	set_process_input(true)
	
	# Crear escudo visual inicialmente oculto
	crear_escudo_visual()
	
	# LÍNEA PARA DETECTAR COLISIONES
	area_entered.connect(_on_area_entered)

# FUNCIÓN PARA DETECTAR COLISIONES CON OBSTÁCULOS
func _on_area_entered(area):
	# Si colisiona con un obstáculo
	if area.is_in_group("obstaculos"):
		# Verificar si tiene escudo activo localmente primero
		if escudo_activo_local:
			# Notificar a Principal que se usó el escudo
			get_parent().usar_escudo()
			print("¡Escudo usado! Te salvaste")
		else:
			morir_por_obstaculo()
			
	# Si colisiona con una moneda
	elif area.is_in_group("monedas"):
		# Notificar a Principal para que maneje la moneda
		get_parent()._on_moneda_recogida(area)
		area.queue_free()  # Eliminar moneda
		
	# Si colisiona con un escudo
	elif area.is_in_group("escudos"):
		get_parent().activar_escudo()
		area.queue_free()
		print("¡Escudo obtenido!")

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

func crear_escudo_visual():
	# Crear un círculo azul transparente alrededor del jugador
	escudo_visual = ColorRect.new()
	escudo_visual.color = Color(0.2, 0.5, 1.0, 0.3)  # Azul semitransparente
	escudo_visual.size = Vector2(70, 70)  # Más grande que el jugador
	escudo_visual.position = Vector2(-35, -35)  # Centrado alrededor del jugador

	# Hacerlo circular (aproximación con radio)
	escudo_visual.material = ShaderMaterial.new()
	var shader_code = """
	shader_type canvas_item;
	render_mode unshaded;

	void fragment() {
		vec2 center = vec2(0.5, 0.5);
		float radius = 0.5;
		float dist = distance(UV, center);

		if (dist > radius) {
			discard;
		}

		COLOR = vec4(0.2, 0.5, 1.0, 0.3);
	}
	"""
	escudo_visual.material.shader = Shader.new()
	escudo_visual.material.shader.code = shader_code

	escudo_visual.visible = false
	add_child(escudo_visual)

func activar_escudo_visual():
	escudo_activo_local = true
	if escudo_visual:
		escudo_visual.visible = true
		# Efecto de parpadeo inicial
		var tween = create_tween()
		tween.tween_property(escudo_visual, "modulate:a", 0.6, 0.2)
		tween.tween_property(escudo_visual, "modulate:a", 0.3, 0.2)
		tween.set_loops(3)

func desactivar_escudo_visual():
	escudo_activo_local = false
	if escudo_visual:
		escudo_visual.visible = false

func tiene_escudo():
	return escudo_activo_local
