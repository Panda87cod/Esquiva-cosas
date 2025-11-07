extends CanvasLayer

var monedas_actuales = 0
var items_tienda = {
	"skin_especial": {
		"nombre": "Skin Especial", 
		"precio": 100, 
		"comprado": false,
		"descripcion": "Nueva apariencia para el jugador"
	},
	"doble_puntos": {
		"nombre": "Doble Puntos", 
		"precio": 50, 
		"comprado": false,
		"descripcion": "Gana el doble de puntos por 30 segundos"
	}
}

func _ready():
	# Cargar datos del jugador
	cargar_datos()
	
	# Configurar UI
	configurar_ui()
	
	# Conectar botones
	$BotonVolver.pressed.connect(_on_volver_presionado)

func cargar_datos():
	# Cargar monedas y estado de compras
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	if error == OK:
		monedas_actuales = config.get_value("monedas", "monedas_acumuladas", 0)
		items_tienda["skin_especial"]["comprado"] = config.get_value("tienda", "skin_especial", false)
		items_tienda["doble_puntos"]["comprado"] = config.get_value("tienda", "doble_puntos", false)

func configurar_ui():
	# Actualizar label de monedas
	$MonedasTienda.text = "Tus monedas: " + str(monedas_actuales)
	
	# Crear items de la tienda
	crear_items_tienda()

func crear_items_tienda():
	var contenedor = $ContenedorItems
	
	# Item 1: Skin Especial
	var item1 = crear_item_ui(
		"Skin Especial", 
		"100 monedas", 
		items_tienda["skin_especial"]["comprado"],
		items_tienda["skin_especial"]["descripcion"]
	)
#	item1.get_node("BotonComprar").pressed.connect(_on_comprar_skin_especial)
#	contenedor.add_child(item1)
	
	# Item 2: Doble Puntos
	var item2 = crear_item_ui(
		"Doble Puntos", 
		"50 monedas", 
		items_tienda["doble_puntos"]["comprado"],
		items_tienda["doble_puntos"]["descripcion"]
	)
#	item2.get_node("BotonComprar").pressed.connect(_on_comprar_doble_puntos)
#	contenedor.add_child(item2)

func crear_item_ui(nombre, precio, comprado, descripcion):
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(400, 80)
	
	# Panel para el item
	var panel = ColorRect.new()
	panel.color = Color(0.2, 0.2, 0.4)
	panel.size = Vector2(400, 70)
	item_container.add_child(panel)
	
	# Contenedor de información
	var info_container = VBoxContainer.new()
	info_container.size = Vector2(250, 60)
	
	# Nombre del item
	var nombre_label = Label.new()
	nombre_label.text = nombre
	nombre_label.add_theme_font_size_override("font_size", 20)
	info_container.add_child(nombre_label)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = descripcion
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_container.add_child(desc_label)
	
	# Precio
	var precio_label = Label.new()
	precio_label.text = precio
	precio_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(precio_label)
	
	panel.add_child(info_container)
	
	# Botón de compra
	var boton_comprar = Button.new()
	boton_comprar.name = "BotonComprar"
	boton_comprar.text = "COMPRAR" if not comprado else "COMPRADO"
	boton_comprar.disabled = comprado
	boton_comprar.size = Vector2(100, 40)
	
	# Posicionar botón a la derecha
	var margin_container = MarginContainer.new()
	margin_container.add_child(boton_comprar)
	panel.add_child(margin_container)
	
	return item_container

func comprar_item(item_key):
	var item = items_tienda[item_key]
	
	if monedas_actuales >= item["precio"] and not item["comprado"]:
		monedas_actuales -= item["precio"]
		item["comprado"] = true
		
		# Guardar cambios
		guardar_datos()
		
		# Actualizar UI
		configurar_ui()
		
		print("¡Item comprado: ", item["nombre"], "!")
	else:
		print("No tienes suficientes monedas o ya compraste este item")

func guardar_datos():
	var config = ConfigFile.new()
	# Cargar configuración existente
	var error = config.load("user://config.cfg")
	if error != OK:
		print("Creando nuevo archivo de configuración")
	
	# Guardar monedas y estado de items
	config.set_value("monedas", "monedas_acumuladas", monedas_actuales)
	config.set_value("tienda", "skin_especial", items_tienda["skin_especial"]["comprado"])
	config.set_value("tienda", "doble_puntos", items_tienda["doble_puntos"]["comprado"])
	
	# Guardar archivo
	config.save("user://config.cfg")
	
	print("Datos guardados correctamente")

func _on_comprar_skin_especial():
	comprar_item("skin_especial")

func _on_comprar_doble_puntos():
	comprar_item("doble_puntos")

func _on_volver_presionado():
	get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")
