# Hangar de stockage. Origine : milieu de la façade, au niveau du quai ; le bâtiment s'étend vers -z.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const SIZE := Vector3(30, 10, 18)
const DOOR_WIDTH := 14.0
const WALL := Color("#6d9ad6")

var letter := "A"
var stock := 0

var _sign: Label3D


func _ready() -> void:
	var cz := -SIZE.z * 0.5
	Blocks.box(self, SIZE, Vector3(0, SIZE.y * 0.5, cz), WALL)
	# Toit à acrotère.
	Blocks.box(self, Vector3(SIZE.x + 0.6, 0.6, SIZE.z + 0.6), Vector3(0, SIZE.y + 0.3, cz), Color("#3d5f9e"))
	Blocks.box(self, Vector3(SIZE.x - 2.0, 0.3, SIZE.z - 2.0), Vector3(0, SIZE.y + 0.6, cz), Color("#4e74b8"))
	# Carrelage façon Globozone : joints horizontaux et verticaux sur la façade.
	for i in range(1, 5):
		Blocks.box(self, Vector3(SIZE.x, 0.06, 0.04), Vector3(0, i * 2.0, 0.03), WALL.darkened(0.12))
	for i in range(1, 10):
		Blocks.box(self, Vector3(0.06, SIZE.y, 0.04), Vector3(-SIZE.x * 0.5 + i * 3.0, SIZE.y * 0.5, 0.03), WALL.darkened(0.12))
	# Grande porte ouverte sur l'intérieur sombre, et son cadre.
	Blocks.box(self, Vector3(DOOR_WIDTH + 1.0, 7.6, 0.3), Vector3(0, 3.8, 0.1), Color("#f08a24"))
	Blocks.box(self, Vector3(DOOR_WIDTH, 7, 0.3), Vector3(0, 3.5, 0.15), Color("#1b2440"))
	# Bandeau de fenêtres lumineuses.
	Blocks.box(self, Vector3(SIZE.x - 4, 0.8, 0.1), Vector3(0, 8.6, 0.05), Color("#9fe4ff"), 0.8)
	# Enseigne avec le stock.
	_sign = Label3D.new()
	_sign.font_size = 96
	_sign.pixel_size = 0.012
	_sign.outline_size = 12
	_sign.modulate = Color("#f4f7fb")
	_sign.outline_modulate = Color("#23304f")
	_sign.position = Vector3(11.0, 5.5, 0.12)
	add_child(_sign)
	_update_sign()


# Emprise au sol (x, z).
func footprint() -> Rect2:
	return Rect2(position.x - SIZE.x * 0.5, position.z - SIZE.z, SIZE.x, SIZE.z)


func store() -> void:
	stock += 1
	_update_sign()


func _update_sign() -> void:
	_sign.text = "HANGAR %s\n%d" % [letter, stock]
