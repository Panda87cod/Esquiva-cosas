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
		
	# Crear obstáculo directamente
	var obstaculo = Area2D.new()
	
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
	
	# Obtener el tamaño de la pantalla para distribución inteligente
	var tamaño_pantalla = get_viewport_rect().size
	
	# Distribución en 3 zonas verticales (arriba, medio, abajo)
	var zona = randi() % 3  # 0=arriba, 1=medio, 2=abajo
	var posicion_y = 0
	
	match zona:
		0:  # Zona superior (20% superior de la pantalla)
			posicion_y = randf_range(100, tamaño_pantalla.y * 0.3)
		1:  # Zona media (30%-70% de la pantalla)
			posicion_y = randf_range(tamaño_pantalla.y * 0.3, tamaño_pantalla.y * 0.7)
		2:  # Zona inferior (30% inferior de la pantalla)
			posicion_y = randf_range(tamaño_pantalla.y * 0.7, tamaño_pantalla.y - 100)
	
	# Posición inicial (fuera de pantalla a la derecha)
	obstaculo.position = Vector2(tamaño_pantalla.x + 50, posicion_y)
	
	# Añadir script de movimiento al obstáculo
	obstaculo.set_script(load("res://Scripts/Obstaculo.gd"))
	
	# Configurar velocidad basada en la dificultad progresiva
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

func actualizar_ui():
	var puntuacion_label = get_node("UILayer/PuntuacionLabel")
	var mejor_puntuacion_label = get_node("UILayer/MejorPuntuacionLabel")
	var monedas_label = get_node("UILayer/MonedasLabel")
	
	if puntuacion_label:
		puntuacion_label.text = "Puntos: " + str(puntuacion)
	
	if mejor_puntuacion_label:
		mejor_puntuacion_label.text = "Mejor: " + str(mejor_puntuacion)
	
	if monedas_label:
		monedas_label.text = "Monedas: " + str(monedas_acumuladas)

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
	get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")

func _on_boton_reinicio_pressed():
	# Recargar la escena actual
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
	
	# Posición aleatoria
	var tamaño_pantalla = get_viewport_rect().size
	moneda.position = Vector2(
		tamaño_pantalla.x + 50, 
		randf_range(150, tamaño_pantalla.y - 150)
	)
	
	# Conectar señal usando bind para pasar la moneda
	moneda.area_entered.connect(_on_moneda_recogida.bind(moneda))
	
	add_child(moneda)

# --- RECOGIDA DE MONEDAS ---
func _on_moneda_recogida(area, moneda):
	# Verificar que fue el jugador
	if area == jugador:
		monedas_acumuladas += 1
		guardar_monedas()
		print("Moneda recogida! Total: ", monedas_acumuladas)
		
		# Reproducir sonido de moneda
		reproducir_sonido(sonido_moneda)
		
		# Eliminar la moneda
		moneda.queue_free()

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
		
		# Preservar compras de tienda si existen
		var skin_comprada = config.get_value("tienda", "skin_especial", false)
		var doble_puntos_comprado = config.get_value("tienda", "doble_puntos", false)
		config.set_value("tienda", "skin_especial", skin_comprada)
		config.set_value("tienda", "doble_puntos", doble_puntos_comprado)
	
	config.save("user://config.cfg")
