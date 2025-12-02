# MenuPrincipal.gd
extends CanvasLayer

# --- REFERENCIAS A NODOS DEL INSPECTOR ---
@onready var mejor_puntuacion_label = $MejorPuntuacion
@onready var creditos_artista_label = $CreditosArtista
@onready var boton_tienda = $BotonTienda
@onready var boton_jugar = $BotonJugar

func _ready():
	# Configurar elementos de UI
	configurar_ui()
	
	# Cargar y mostrar datos del jugador
	cargar_datos_jugador()
	
	# Conectar señales de botones
	conectar_botones()

func configurar_ui():
	# Configurar BotonTienda (posición y texto desde código)
	boton_tienda.position = Vector2(260, 435)
	boton_tienda.size = Vector2(200, 60)
	boton_tienda.text = "TIENDA"
	boton_tienda.add_theme_font_size_override("font_size", 24)
	
	# Configurar CreditosArtista (solo posición desde código, texto queda del inspector)
	creditos_artista_label.position = Vector2(20, 720)
	creditos_artista_label.size = Vector2(300, 25)
	creditos_artista_label.add_theme_font_size_override("font_size", 18)
	creditos_artista_label.modulate = Color(1, 1, 1, 0.8)

func cargar_datos_jugador():
	# Cargar mejor puntuación
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	
	if error == OK:
		# Cargar mejor puntuación
		var mejor_puntuacion = config.get_value("puntuaciones", "mejor_puntuacion", 0)
		mejor_puntuacion_label.text = "Mejor Puntuación: " + str(mejor_puntuacion)
	else:
		# Valores por defecto
		mejor_puntuacion_label.text = "Mejor Puntuación: 0"

func conectar_botones():
	# Conectar botones existentes
	boton_jugar.pressed.connect(_on_boton_jugar_presionado)
	boton_tienda.pressed.connect(_on_boton_tienda_presionado)

# --- SEÑALES DE BOTONES ---
func _on_boton_jugar_presionado():
	get_tree().change_scene_to_file("res://Escenas/Principal.tscn")

func _on_boton_tienda_presionado():
	get_tree().change_scene_to_file("res://Escenas/Tienda.tscn")
