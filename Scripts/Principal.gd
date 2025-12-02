# Principal.gd
extends Node2D

# --- VARIABLES DE SONIDOS ---
@onready var audio_player = $AudioStreamPlayer
var sonido_salto = preload("res://Sonidos/salto.wav")
var sonido_game_over = preload("res://Sonidos/game_over.wav")
var sonido_punto = preload("res://Sonidos/punto.wav")
var sonido_moneda = preload("res://Sonidos/moneda.wav")

# Variables de monedas
var monedas_acumuladas = 0
var timer_monedas

# Variables de escudos
var escudo_activo = false
var timer_escudos
var escudo_comprado = false  # Para saber si se compró en tienda
var escudo_en_pantalla = null  # Referencia al escudo actual en pantalla

# Variables del juego
@onready var jugador = $Jugador
@onready var timer_obstaculos = $GeneradorObstaculos
var puntuacion = 0
var mejor_puntuacion = 0
var juego_activo = true
var velocidad_base_obstaculos = 280
var tiempo_transcurrido = 0.0

# Control de frecuencia de obstáculos
var frecuencia_obstaculos = 2.0 # Tiempo entre obstáculos (segundos)

# Margenes
var margen_superior = 150  # No aparecen obstáculos arriba de 150px
var margen_inferior = 200  # No aparecen obstáculos abajo de (pantalla - 200px)
var zona_segura_centro = 150  # Espacio seguro en el centro para el jugador

func _ready():
	# Configurar conexiones
	timer_obstaculos.timeout.connect(_generar_obstaculo)
	jugador.juego_terminado.connect(_on_jugador_game_over)
	jugador.solicitar_sonido_salto.connect(_on_salto_solicitado)
	
	# Configurar timer de obstáculos con frecuencia inicial
	timer_obstaculos.wait_time = frecuencia_obstaculos
	timer_obstaculos.autostart = true
	
	# Timer para monedas (cada 5-8 segundos)
	timer_monedas = Timer.new()
	timer_monedas.wait_time = 6.5
	timer_monedas.autostart = true
	timer_monedas.timeout.connect(_generar_moneda)
	add_child(timer_monedas)
	
	# Cargar monedas guardadas
	cargar_monedas()
	
	# Timer para escudos (solo si están comprados)
	timer_escudos = Timer.new()
	timer_escudos.wait_time = 15.0  # Cada 15 segundos
	timer_escudos.autostart = true
	timer_escudos.timeout.connect(_generar_escudo)
	add_child(timer_escudos)
	
	# Cargar si el escudo está comprado
	cargar_estado_escudo()
	
	# Cargar mejor puntuación guardada
	cargar_mejor_puntuacion()
	
	# Inicializar UI
	inicializar_ui()

func _process(delta):
	if juego_activo and jugador.esta_vivo:
		# Actualizar puntuación (1 punto por segundo)
		tiempo_transcurrido += delta
		var nueva_puntuacion = int(tiempo_transcurrido)
		
		# REPRODUCIR SONIDO CADA 10 PUNTOS
		if nueva_puntuacion > puntuacion and nueva_puntuacion % 10 == 0 and nueva_puntuacion > 0:
			reproducir_sonido(sonido_punto)
		
		puntuacion = nueva_puntuacion
		actualizar_ui()
		
		# Aumentar dificultad progresivamente
		aumentar_dificultad_progresiva()

func _generar_obstaculo():
	if not juego_activo or not jugador.esta_vivo:
		return
	
	# Crear obstáculo directamente desde código
	var obstaculo = Area2D.new()
	obstaculo.set_script(preload("res://Scripts/Obstaculo.gd"))
	
	# Añadir al grupo de obstáculos
	obstaculo.add_to_group("obstaculos")
	
	# Añadir forma visual (ColorRect verde)
	var forma_visual = ColorRect.new()
	forma_visual.color = Color.GREEN
	forma_visual.size = Vector2(80, 40)
	obstaculo.add_child(forma_visual)
	
	# Añadir colisión
	var colision = CollisionShape2D.new()
	colision.shape = RectangleShape2D.new()
	colision.shape.size = Vector2(80, 40)
	obstaculo.add_child(colision)
	
	# Obtener el tamaño de la pantalla
	var tamaño_pantalla = get_viewport_rect().size
	
	# Calcular altura disponible (excluyendo márgenes)
	var altura_disponible = tamaño_pantalla.y - margen_superior - margen_inferior
	var altura_zona = altura_disponible / 3  # Dividimos en 3 zonas iguales
	
	# Distribución en 3 zonas verticales
	var zona = randi() % 3  # 0=arriba, 1=medio, 2=abajo
	var posicion_y = 0
	
	match zona:
		0:  # Zona superior (arriba del centro)
			# Desde margen_superior hasta margen_superior + altura_zona
			posicion_y = randf_range(margen_superior, margen_superior + altura_zona)
		1:  # Zona media (justo el centro - ¡zona SEGURA! Sin obstáculos aquí)
			# El centro es zona segura, así que si sale zona 1, generamos en zona 0 o 2
			# Esto evita que el centro sea muy fácil pero tampoco imposible
			var elegir = randi() % 2
			if elegir == 0:
				posicion_y = randf_range(margen_superior, margen_superior + altura_zona)
			else:
				posicion_y = randf_range(margen_superior + altura_zona * 2, tamaño_pantalla.y - margen_inferior)
		2:  # Zona inferior (abajo del centro)
			# Desde margen_superior + altura_zona*2 hasta pantalla - margen_inferior
			posicion_y = randf_range(margen_superior + altura_zona * 2, tamaño_pantalla.y - margen_inferior)
	
	# Posición inicial (fuera de pantalla a la derecha)
	obstaculo.position = Vector2(tamaño_pantalla.x + 50, posicion_y)
	
	# Configurar velocidad
	if obstaculo.has_method("set_velocidad"):
		obstaculo.set_velocidad(velocidad_base_obstaculos)
	
	# Añadir a la escena
	add_child(obstaculo)

# --- SISTEMA DE SONIDOS ---
func reproducir_sonido(sonido):
	if audio_player and sonido:
		audio_player.stream = sonido
		audio_player.play()

func _on_salto_solicitado():
	reproducir_sonido(sonido_salto)

# --- SISTEMA DE PUNTUACIÓN Y UI ---
func inicializar_ui():
	# Crear CanvasLayer para UI si no existe
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	
	# Label de puntuación
	var puntuacion_label = Label.new()
	puntuacion_label.name = "PuntuacionLabel"
	puntuacion_label.position = Vector2(20, 20)
	puntuacion_label.add_theme_font_size_override("font_size", 36)
	ui_layer.add_child(puntuacion_label)
	
	# Label de mejor puntuación
	var mejor_puntuacion_label = Label.new()
	mejor_puntuacion_label.name = "MejorPuntuacionLabel"
	mejor_puntuacion_label.position = Vector2(20, 70)
	mejor_puntuacion_label.add_theme_font_size_override("font_size", 24)
	ui_layer.add_child(mejor_puntuacion_label)
	
	# Label de monedas
	var monedas_label = Label.new()
	monedas_label.name = "MonedasLabel"
	monedas_label.position = Vector2(20, 120)
	monedas_label.add_theme_font_size_override("font_size", 24)
	monedas_label.text = "Monedas: " + str(monedas_acumuladas)
	ui_layer.add_child(monedas_label)
	
	# Label de escudo
	var escudo_label = Label.new()
	escudo_label.name = "EscudoLabel"
	escudo_label.position = Vector2(20, 170)  # Debajo de monedas
	escudo_label.add_theme_font_size_override("font_size", 20)
	escudo_label.text = "Escudo: NO"
	escudo_label.modulate = Color(0.2, 0.5, 1.0)  # Azul
	ui_layer.add_child(escudo_label)

func actualizar_ui():
	var puntuacion_label = get_node("UILayer/PuntuacionLabel")
	var mejor_puntuacion_label = get_node("UILayer/MejorPuntuacionLabel")
	var monedas_label = get_node("UILayer/MonedasLabel")
	var escudo_label = get_node("UILayer/EscudoLabel")
	
	if puntuacion_label:
		puntuacion_label.text = "Puntos: " + str(puntuacion)
	
	if mejor_puntuacion_label:
		mejor_puntuacion_label.text = "Mejor: " + str(mejor_puntuacion)
	
	if monedas_label:
		monedas_label.text = "Monedas: " + str(monedas_acumuladas)
	
	if escudo_label:
		if escudo_activo:
			escudo_label.text = "Escudo: ACTIVO"
			escudo_label.modulate = Color(0.0, 1.0, 0.0)  # Verde cuando está activo
		else:
			escudo_label.text = "Escudo: NO"
			escudo_label.modulate = Color(0.2, 0.5, 1.0)  # Azul cuando no

# --- SISTEMA DE GUARDADO ---
func cargar_mejor_puntuacion():
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	if error == OK:
		mejor_puntuacion = config.get_value("puntuaciones", "mejor_puntuacion", 0)

func guardar_mejor_puntuacion():
	var config = ConfigFile.new()
	config.set_value("puntuaciones", "mejor_puntuacion", mejor_puntuacion)
	config.save("user://config.cfg")

# --- DIFICULTAD PROGRESIVA ---
func aumentar_dificultad_progresiva():
	# Cada 15 segundos aumenta la velocidad base
	if int(tiempo_transcurrido) % 15 == 0 and int(tiempo_transcurrido) > 0:
		velocidad_base_obstaculos += 8
		# Reducir tiempo entre obstáculos
		frecuencia_obstaculos = max(0.6, frecuencia_obstaculos - 0.15)  # Más obstáculos
		timer_obstaculos.wait_time = frecuencia_obstaculos

# --- GAME OVER Y REINICIO ---
func game_over():
	if not juego_activo:
		return
		
	juego_activo = false
	
	# Reproducir sonido de game over
	reproducir_sonido(sonido_game_over)
	
	# Si tenía escudo activo, desactivarlo y reiniciar timer
	if escudo_activo:
		usar_escudo() # Esto desactiva el escudo y reinicia el timer
	
	# Actualizar mejor puntuación si es necesario
	if puntuacion > mejor_puntuacion:
		mejor_puntuacion = puntuacion
		guardar_mejor_puntuacion()
	
	# Mostrar pantalla de game over
	mostrar_pantalla_game_over()

func mostrar_pantalla_game_over():
	# Crear fondo semi-transparente
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.size = get_viewport_rect().size
	fondo.name = "FondoGameOver"
	get_node("UILayer").add_child(fondo)
	
	# Texto de Game Over
	var game_over_label = Label.new()
	game_over_label.text = "¡JUEGO TERMINADO!"
	game_over_label.position = Vector2(0, 250)
	game_over_label.size = Vector2(720, 60)
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fondo.add_child(game_over_label)
	
	# Texto de puntuación
	var puntos_label = Label.new()
	puntos_label.text = "Puntos: " + str(puntuacion) + "\nMejor: " + str(mejor_puntuacion)
	puntos_label.position = Vector2(0, 330)
	puntos_label.size = Vector2(720, 80)
	puntos_label.add_theme_font_size_override("font_size", 32)
	puntos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fondo.add_child(puntos_label)
	
	# Botón de reinicio
	var boton_reinicio = Button.new()
	boton_reinicio.text = "JUGAR DE NUEVO"
	boton_reinicio.position = Vector2(260, 450)
	boton_reinicio.size = Vector2(200, 60)
	boton_reinicio.add_theme_font_size_override("font_size", 24)
	boton_reinicio.connect("pressed", _on_boton_reinicio_pressed)
	fondo.add_child(boton_reinicio)
	
	# Botón para volver al menú
	var boton_menu = Button.new()
	boton_menu.text = "VOLVER AL MENÚ"
	boton_menu.position = Vector2(260, 530)
	boton_menu.size = Vector2(200, 60)
	boton_menu.add_theme_font_size_override("font_size", 24)
	boton_menu.connect("pressed", _on_boton_menu_pressed)
	fondo.add_child(boton_menu)

# Volver al menú principal
func _on_boton_menu_pressed():
	# Limpiar TODOS los obstáculos y monedas antes de cambiar escena
	limpiar_obstaculos()
	limpiar_monedas()
	get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")

func limpiar_obstaculos():
	for obstaculo in get_tree().get_nodes_in_group("obstaculos"):
		obstaculo.queue_free()

func limpiar_monedas():
	for moneda in get_tree().get_nodes_in_group("monedas"):
		moneda.queue_free()

func _on_boton_reinicio_pressed():
	# Limpiar TODOS los obstáculos, monedas y escudos antes de recargar la escena actual
	limpiar_obstaculos()
	limpiar_monedas()
	limpiar_escudos()
	
	# Si el escudo está comprado y no está activo, reiniciar timer
	if escudo_comprado and not escudo_activo:
		timer_escudos.start()
	
	get_tree().reload_current_scene()

# --- CONEXIÓN CON JUGADOR ---
func _on_jugador_game_over():
	game_over()

# --- GENERACIÓN DE MONEDAS ---
func _generar_moneda():
	if not juego_activo or not jugador.esta_vivo:
		return
		
	# Crear moneda directamente
	var moneda = Area2D.new()
	moneda.set_script(preload("res://Scripts/MonedaMovimiento.gd"))
	
	# AÑADIR GRUPO
	moneda.add_to_group("monedas")
	
	# Sprite visual simple (círculo amarillo)
	var sprite = ColorRect.new()
	sprite.color = Color.YELLOW
	sprite.size = Vector2(25, 25)
	moneda.add_child(sprite)
	
	# Colisión
	var colision = CollisionShape2D.new()
	colision.shape = CircleShape2D.new()
	colision.shape.radius = 12
	moneda.add_child(colision)
	
	# Posición aleatoria con márgenes ajustados
	var tamaño_pantalla = get_viewport_rect().size
	
	# Monedas pueden aparecer en cualquier zona, pero evitando extremos
	var altura_disponible = tamaño_pantalla.y - margen_superior - margen_inferior
	var posicion_y = randf_range(margen_superior, tamaño_pantalla.y - margen_inferior)
	
	moneda.position = Vector2(tamaño_pantalla.x + 50, posicion_y)
	
	add_child(moneda)

# --- RECOGIDA DE MONEDAS ---
func _on_moneda_recogida(moneda):
	monedas_acumuladas += 1
	guardar_monedas()
	reproducir_sonido(sonido_moneda)
	# La moneda ya se elimina en Jugador.gd

# --- SISTEMA DE GUARDADO MEJORADO ---
func cargar_monedas():
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	if error == OK:
		monedas_acumuladas = config.get_value("monedas", "monedas_acumuladas", 0)

func guardar_monedas():
	var config = ConfigFile.new()
	# Cargar configuración existente primero
	var error = config.load("user://config.cfg")
	if error != OK:
		print("Creando nuevo archivo de configuración")
	
	# Solo actualizar las monedas, mantener otros valores
	config.set_value("monedas", "monedas_acumuladas", monedas_acumuladas)
	
	# Mantener valores existentes si los hay
	if error == OK:
		# Preservar mejor puntuación
		var mejor_puntuacion_existente = config.get_value("puntuaciones", "mejor_puntuacion", 0)
		config.set_value("puntuaciones", "mejor_puntuacion", mejor_puntuacion_existente)
		
		# Preservar compra de escudo si existe
		var escudo_comprado = config.get_value("tienda", "escudo", false)
		config.set_value("tienda", "escudo", escudo_comprado)
	
	config.save("user://config.cfg")

func cargar_estado_escudo():
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	if error == OK:
		escudo_comprado = config.get_value("tienda", "escudo", false)
		# Si no está comprado, detener el timer
		if not escudo_comprado:
			timer_escudos.stop()

func _generar_escudo():
	# NO generar si: juego inactivo, jugador muerto, escudo no comprado, O si jugador ya tiene escudo activo
	if not juego_activo or not jugador.esta_vivo or not escudo_comprado or escudo_activo:
		return
		
	if escudo_en_pantalla and is_instance_valid(escudo_en_pantalla):
		return  # Ya hay un escudo en pantalla, no generar otro
	
	# Crear escudo
	var escudo = Area2D.new()
	escudo.set_script(preload("res://Scripts/Escudo.gd"))
	escudo.add_to_group("escudos")
	
	# Posición aleatoria (usando los mismos márgenes que obstáculos)
	var tamaño_pantalla = get_viewport_rect().size
	
	# Los escudos aparecen en zonas MEDIAS, no extremas
	# Para hacerlos alcanzables pero no demasiado fáciles
	var altura_disponible = tamaño_pantalla.y - margen_superior - margen_inferior
	var altura_zona = altura_disponible / 3
	
	# 70% de probabilidad en zona media, 30% en otras
	var probabilidad = randf()
	var posicion_y = 0
	
	if probabilidad < 0.7:  # Zona media (más común)
		posicion_y = randf_range(margen_superior + altura_zona, margen_superior + altura_zona * 2)
	else:  # Zonas superior o inferior
		var elegir = randi() % 2
		if elegir == 0:
			posicion_y = randf_range(margen_superior, margen_superior + altura_zona)
		else:
			posicion_y = randf_range(margen_superior + altura_zona * 2, tamaño_pantalla.y - margen_inferior)
	
	escudo.position = Vector2(tamaño_pantalla.x + 50, posicion_y)
	
	add_child(escudo)
	escudo_en_pantalla = escudo  # Guardar referencia al escudo actual
	print("Escudo generado en pantalla - Posición Y: ", posicion_y)

func activar_escudo():
	escudo_activo = true
	# Activar el escudo visual en el jugador
	jugador.activar_escudo_visual()
	
	# Detener el timer de generación de nuevos escudos
	timer_escudos.stop()
	print("Timer de escudos DETENIDO - Jugador tiene escudo activo")
	
	# Limpiar referencia al escudo en pantalla (ya fue recogido)
	escudo_en_pantalla = null

	# Sonido opcional (puedes agregar un sonido de escudo)
	# reproducir_sonido(preload("res://Sonidos/escudo.wav"))
	print("Escudo activado - ¡Protegido!")

func usar_escudo():
	escudo_activo = false
	# Desactivar el escudo visual en el jugador
	jugador.desactivar_escudo_visual()
	
	# Reiniciar el timer para generar nuevos escudos
	timer_escudos.start()
	print("Timer de escudos REINICIADO - Jugador perdió escudo")

	# Efecto visual cuando se usa el escudo
	var particulas = GPUParticles2D.new()
	particulas.position = jugador.position
	particulas.emitting = true
	particulas.one_shot = true
	particulas.lifetime = 0.5
	add_child(particulas)
	
	# Eliminar partículas después de un tiempo
	get_tree().create_timer(1.0).timeout.connect(particulas.queue_free)
	
	print("Escudo consumido")

func limpiar_escudos():
	for escudo in get_tree().get_nodes_in_group("escudos"):
		escudo.queue_free()
	escudo_en_pantalla = null  # Limpiar referencia
