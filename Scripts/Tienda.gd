# Tienda.gd - VERSIÓN ESCALABLE
extends CanvasLayer

var monedas_actuales = 0

# Diccionario de items disponibles en la tienda
# ¡Para agregar nuevos items solo añade una nueva entrada aquí!
var items_tienda = {
	"escudo": {
		"nombre": "Escudo Protector", 
		"precio": 30, 
		"comprado": false,
		"descripcion": "Te protege de un obstáculo. Aparecerá durante el juego.",
		"funcion_comprar": "_on_comprar_escudo"
	}
	# Para agregar un nuevo item en el futuro:
	# "doble_monedas": {
	#     "nombre": "Doble Monedas",
	#     "precio": 50,
	#     "comprado": false,
	#     "descripcion": "Gana el doble de monedas por 30 segundos",
	#     "funcion_comprar": "_on_comprar_doble_monedas"
	# }
}

func _ready():
	cargar_datos()
	configurar_ui()
	$BotonVolver.pressed.connect(_on_volver_presionado)

func cargar_datos():
	var config = ConfigFile.new()
	
	# Usar ruta condicional
	var ruta
	if OS.has_feature("android"):
		ruta = OS.get_user_data_dir() + "/config.cfg"
	else:
		ruta = "user://config.cfg"
	
	var error = config.load(ruta)
	if error == OK:
		monedas_actuales = config.get_value("monedas", "monedas_acumuladas", 0)
		items_tienda["escudo"]["comprado"] = config.get_value("tienda", "escudo", false)

func configurar_ui():
	$MonedasTienda.text = "Tus monedas: " + str(monedas_actuales)
	crear_items_tienda()

func crear_items_tienda():
	var contenedor = $ContenedorObjetos
	
	# Limpiar contenedor
	for child in contenedor.get_children():
		child.queue_free()
	
	# Crear un item para CADA entrada en items_tienda
	for item_key in items_tienda.keys():
		var item = items_tienda[item_key]
		var item_ui = crear_item_ui(
			item["nombre"],
			item["precio"],
			item["comprado"],
			item["descripcion"],
			item_key
		)
		contenedor.add_child(item_ui)

func crear_item_ui(nombre, precio, comprado, descripcion, item_key):
	# Contenedor principal horizontal
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(380, 100)
	item_container.name = "Item_" + item_key  # Nombre único para referencia
	
	# Información (izquierda) - Ocupa TODO el espacio disponible
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Nombre del item
	var nombre_label = Label.new()
	nombre_label.text = nombre
	nombre_label.add_theme_font_size_override("font_size", 22)
	info_container.add_child(nombre_label)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = descripcion
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.9, 0.9, 0.9)
	info_container.add_child(desc_label)
	
	# Precio
	var precio_label = Label.new()
	precio_label.text = "Precio: " + str(precio) + " monedas"
	precio_label.add_theme_font_size_override("font_size", 18)
	precio_label.modulate = Color(1, 0.8, 0.2)
	info_container.add_child(precio_label)
	
	item_container.add_child(info_container)
	
	# Botón (derecha)
	var boton_comprar = Button.new()
	boton_comprar.name = "Boton_" + item_key  # Nombre único para el botón
	boton_comprar.text = "COMPRAR" if not comprado else "✓"
	boton_comprar.disabled = comprado
	boton_comprar.custom_minimum_size = Vector2(80, 50)
	boton_comprar.add_theme_font_size_override("font_size", 16)
	
	# Conectar la señal usando Callable y bind para pasar el item_key
	boton_comprar.pressed.connect(_on_boton_comprar_presionado.bind(item_key))
	
	item_container.add_child(boton_comprar)
	
	# Fondo con márgenes
	var panel = ColorRect.new()
	panel.color = Color(0.15, 0.15, 0.3, 0.8)
	panel.size = Vector2(400, 95)
	panel.add_child(item_container)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 10)
	margin.add_child(panel)
	
	return margin

# Función GENERAL para manejar compras de cualquier item
func _on_boton_comprar_presionado(item_key):
	comprar_item(item_key)

func comprar_item(item_key):
	var item = items_tienda[item_key]
	
	if monedas_actuales >= item["precio"] and not item["comprado"]:
		monedas_actuales -= item["precio"]
		item["comprado"] = true
		
		guardar_datos()
		configurar_ui()  # Esto recreará todos los items con estados actualizados
		
		print("¡Item comprado: ", item["nombre"], "!")
		
		# Llamar a función específica si existe
		if item.has("funcion_comprar") and has_method(item["funcion_comprar"]):
			call(item["funcion_comprar"])
	else:
		print("No tienes suficientes monedas o ya compraste este item")

func guardar_datos():
	var config = ConfigFile.new()
	
	# Usar ruta condicional
	var ruta
	if OS.has_feature("android"):
		ruta = OS.get_user_data_dir() + "/config.cfg"
	else:
		ruta = "user://config.cfg"
	
	# Cargar configuración existente
	var error = config.load(ruta)
	
	# Solo guardar monedas y estado del escudo
	config.set_value("monedas", "monedas_acumuladas", monedas_actuales)
	config.set_value("tienda", "escudo", items_tienda["escudo"]["comprado"])
	
	# Guardar archivo
	config.save(ruta)

# Funciones específicas para cada item (se llaman automáticamente después de comprar)
func _on_comprar_escudo():
	print("¡Escudo desbloqueado! Aparecerá en el juego.")
	# Aquí puedes agregar lógica específica para el escudo
	# Por ejemplo: notificar a la escena Principal que el escudo está desbloqueado

# Para agregar un nuevo item en el futuro, solo necesitas:
# 1. Agregar una entrada en items_tienda
# 2. Crear una función _on_comprar_[nombre_item]() si necesitas lógica específica

func _on_volver_presionado():
	get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")
