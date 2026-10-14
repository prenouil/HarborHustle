# Console de commande de la grue, tournée vers l'eau (+z).
# Une balise lumineuse tourne au-dessus tant qu'un bateau attend d'être déchargé.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const FOOTPRINT := Vector2(1.5, 1.0)

var _beacon: Node3D
var _time := 0.0


func _ready() -> void:
	var body := Color("#2a3150")
	Blocks.box(self, Vector3(FOOTPRINT.x, 1.0, FOOTPRINT.y), Vector3(0, 0.5, 0), body)
	Blocks.box(self, Vector3(FOOTPRINT.x + 0.1, 0.1, FOOTPRINT.y + 0.1), Vector3(0, 0.05, 0), Color("#14151a"))
	# Pupitre incliné vers l'utilisateur, avec écran et boutons.
	var desk := Node3D.new()
	desk.position = Vector3(0, 1.1, 0.05)
	desk.rotation.x = deg_to_rad(28)
	add_child(desk)
	Blocks.box(desk, Vector3(1.6, 0.15, 1.0), Vector3.ZERO, Color("#3d4a70"))
	Blocks.box(desk, Vector3(0.9, 0.04, 0.5), Vector3(-0.2, 0.09, -0.1), Color("#6fd3ff"), 1.2)
	Blocks.box(desk, Vector3(0.22, 0.1, 0.22), Vector3(0.5, 0.11, -0.1), Color("#3ddc6a"), 1.0)
	for i in 3:
		var colors := [Color("#f2c230"), Color("#2f6fd6"), Color("#d6402f")]
		Blocks.box(desk, Vector3(0.14, 0.06, 0.1), Vector3(-0.5 + i * 0.3, 0.09, 0.32), colors[i])
	# Écran de contrôle vertical à l'arrière.
	Blocks.box(self, Vector3(0.15, 1.0, 0.15), Vector3(0, 1.6, -0.35), body)
	Blocks.box(self, Vector3(1.4, 0.9, 0.12), Vector3(0, 2.4, -0.35), body)
	Blocks.box(self, Vector3(1.25, 0.75, 0.02), Vector3(0, 2.4, -0.28), Color("#2f6fd6"), 0.8)
	Blocks.box(self, Vector3(0.7, 0.35, 0.02), Vector3(0, 2.4, -0.265), Color("#9fe4ff"), 1.0)
	# Balise.
	_beacon = Node3D.new()
	_beacon.position = Vector3(0, 3.6, 0)
	add_child(_beacon)
	var gem := Blocks.box(_beacon, Vector3(0.5, 0.5, 0.5), Vector3.ZERO, Color("#f2c230"), 2.0)
	gem.rotation = Vector3(deg_to_rad(45), 0, deg_to_rad(45))


func _process(delta: float) -> void:
	_time += delta
	_beacon.position.y = 3.6 + sin(_time * 3.0) * 0.15
	_beacon.rotation.y += delta * 2.0


func set_beacon(on: bool) -> void:
	_beacon.visible = on


# Volume cliquable, en coordonnées globales.
func hit_box() -> AABB:
	return AABB(global_position + Vector3(-1.0, 0, -0.8), Vector3(2.0, 4.2, 1.6))


# Emprise au sol (x, z), pour que le héros la contourne.
func footprint() -> Rect2:
	return Rect2(global_position.x - FOOTPRINT.x * 0.5, global_position.z - FOOTPRINT.y * 0.5, FOOTPRINT.x, FOOTPRINT.y)


# Où le héros se place pour l'utiliser.
func stand_point() -> Vector3:
	return to_global(Vector3(0, 0, 1.3))
