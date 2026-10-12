# Le port : eau, quai, hangars et mobilier. Le bord du quai longe z = 0, l'eau est côté +z.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")
const WATER_SHADER = preload("res://shaders/water.gdshader")

const QUAY_Y := 1.5
const QUAY_WIDTH := 270.0
const QUAY_DEPTH := 60.0
const HANGAR_SIZE := Vector3(30, 10, 18)
const HANGAR_FRONT_Z := -24.0
const HANGAR_XS := [-36.0, 0.0, 36.0]
const BOLLARD_XS := [-42.0, -30.0, -18.0, -6.0, 6.0, 18.0, 30.0, 42.0]
const LAMP_XS := [-54.0, -18.0, 18.0, 54.0]
const LAMP_Z := -20.5
const PALLET_SPOTS := [Vector3(-24, 0, -21), Vector3(-21.6, 0, -21.2), Vector3(14, 0, -20.5), Vector3(48, 0, -21)]
# Rails de la grue, le long du quai.
const RAIL_ZS := [-4.0, -12.0]
# Zone du quai où l'on peut marcher (x, z) : on reste à distance du bord.
const WALK_AREA := Rect2(-78, -58, 156, 56.8)

const CONCRETE := Color("#5d6a8c")
const PAVEMENT := Color("#4a5578")
const SAFETY := Color("#f2c230")


func _ready() -> void:
	_build_water()
	_build_quay()
	for i in HANGAR_XS.size():
		_build_hangar(HANGAR_XS[i], "ABC"[i])
	_build_props()


# Emprises au sol (x, z) des éléments fixes que l'on ne peut pas traverser.
func obstacles() -> Array[Rect2]:
	var list: Array[Rect2] = []
	for x in HANGAR_XS:
		list.append(Rect2(x - HANGAR_SIZE.x * 0.5, HANGAR_FRONT_Z - HANGAR_SIZE.z, HANGAR_SIZE.x, HANGAR_SIZE.z))
	for x in BOLLARD_XS:
		list.append(Rect2(x - 0.5, -2.0, 1.0, 1.0))
	for x in LAMP_XS:
		list.append(Rect2(x - 0.2, LAMP_Z - 0.2, 0.4, 0.4))
	for spot in PALLET_SPOTS:
		list.append(Rect2(spot.x - 1.1, spot.z - 1.0, 2.2, 2.0))
	return list


# Amarre le bateau aux bollards, avec des cordages de l'avant et de l'arrière.
func moor(ship) -> void:
	var lines := [
		[ship.cleat(27.0, -1), Vector3(42, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(20.0, -1), Vector3(30, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(-27.0, -1), Vector3(-42, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(-20.0, -1), Vector3(-30, QUAY_Y + 0.6, -1.5)],
	]
	for line in lines:
		Blocks.beam(self, ship.to_global(line[0]), line[1], 0.07, Color("#e8dcc0"))


func _build_water() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(700, 700)
	mesh.subdivide_width = 140
	mesh.subdivide_depth = 140
	var water := MeshInstance3D.new()
	water.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _build_quay() -> void:
	var bottom := -6.0
	Blocks.box(self, Vector3(QUAY_WIDTH, QUAY_Y - bottom, QUAY_DEPTH),
		Vector3(0, (QUAY_Y + bottom) * 0.5, -QUAY_DEPTH * 0.5), CONCRETE)
	# Voie de circulation devant les hangars, bande de sécurité et bord du quai.
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.02, 12), Vector3(0, QUAY_Y + 0.01, -10), PAVEMENT)
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.03, 0.5), Vector3(0, QUAY_Y + 0.015, -2.6), SAFETY)
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.4, 0.8), Vector3(0, QUAY_Y + 0.05, -0.4), Color("#7b88a8"))
	for z in RAIL_ZS:
		Blocks.box(self, Vector3(QUAY_WIDTH, 0.06, 0.25), Vector3(0, QUAY_Y + 0.03, z), Color("#2a3150"))
	var count := int(QUAY_WIDTH / 6.0)
	for i in count:
		var x := -QUAY_WIDTH * 0.5 + 3.0 + i * 6.0
		Blocks.box(self, Vector3(2.4, 0.05, 0.3), Vector3(x, QUAY_Y + 0.03, -14.5), Color("#d9dee8"))
		# Défenses en caoutchouc sur la face du quai.
		Blocks.box(self, Vector3(1.2, 1.6, 0.5), Vector3(x + 3.0, 0.3, 0.2), Color("#1a1d26"))


func _build_hangar(x: float, letter: String) -> void:
	var size := HANGAR_SIZE
	var cz := HANGAR_FRONT_Z - size.z * 0.5
	var wall := Color("#6d9ad6")
	Blocks.box(self, size, Vector3(x, QUAY_Y + size.y * 0.5, cz), wall)
	# Toit à acrotère.
	Blocks.box(self, Vector3(size.x + 0.6, 0.6, size.z + 0.6), Vector3(x, QUAY_Y + size.y + 0.3, cz), Color("#3d5f9e"))
	Blocks.box(self, Vector3(size.x - 2.0, 0.3, size.z - 2.0), Vector3(x, QUAY_Y + size.y + 0.6, cz), Color("#4e74b8"))
	# Carrelage façon Globozone : joints horizontaux et verticaux sur la façade.
	var front := HANGAR_FRONT_Z + 0.03
	for i in range(1, 5):
		Blocks.box(self, Vector3(size.x, 0.06, 0.04), Vector3(x, QUAY_Y + i * 2.0, front), wall.darkened(0.12))
	for i in range(1, 10):
		Blocks.box(self, Vector3(0.06, size.y, 0.04), Vector3(x - size.x * 0.5 + i * 3.0, QUAY_Y + size.y * 0.5, front), wall.darkened(0.12))
	# Grande porte et son cadre.
	Blocks.box(self, Vector3(13, 7.6, 0.3), Vector3(x, QUAY_Y + 3.8, HANGAR_FRONT_Z + 0.1), Color("#f08a24"))
	Blocks.box(self, Vector3(12, 7, 0.3), Vector3(x, QUAY_Y + 3.5, HANGAR_FRONT_Z + 0.15), Color("#23304f"))
	for i in range(1, 7):
		Blocks.box(self, Vector3(12, 0.05, 0.05), Vector3(x, QUAY_Y + i * 1.0, HANGAR_FRONT_Z + 0.32), Color("#2f3e63"))
	# Bandeau de fenêtres lumineuses.
	Blocks.box(self, Vector3(size.x - 4, 0.8, 0.1), Vector3(x, QUAY_Y + 8.6, HANGAR_FRONT_Z + 0.05), Color("#9fe4ff"), 0.8)
	# Enseigne.
	var sign := Label3D.new()
	sign.text = "HANGAR " + letter
	sign.font_size = 96
	sign.pixel_size = 0.012
	sign.outline_size = 12
	sign.modulate = Color("#f4f7fb")
	sign.outline_modulate = Color("#23304f")
	sign.position = Vector3(x + 10.5, QUAY_Y + 6.5, HANGAR_FRONT_Z + 0.12)
	add_child(sign)


func _build_props() -> void:
	for x in BOLLARD_XS:
		Blocks.cylinder(self, 0.35, 0.8, Vector3(x, QUAY_Y + 0.4, -1.5), Color("#1a1d26"))
		Blocks.cylinder(self, 0.5, 0.15, Vector3(x, QUAY_Y + 0.85, -1.5), Color("#1a1d26"))
	# Lampadaires, devant les hangars (hors du passage de la grue).
	for x in LAMP_XS:
		Blocks.box(self, Vector3(0.3, 7, 0.3), Vector3(x, QUAY_Y + 3.5, LAMP_Z), Color("#2a3150"))
		Blocks.box(self, Vector3(1.6, 0.3, 0.6), Vector3(x + 0.6, QUAY_Y + 7.0, LAMP_Z), Color("#2a3150"))
		Blocks.box(self, Vector3(1.2, 0.12, 0.45), Vector3(x + 0.8, QUAY_Y + 6.82, LAMP_Z), Color("#ffd8a0"), 3.0)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffcf8a")
		lamp.omni_range = 9.0
		lamp.light_energy = 1.2
		lamp.position = Vector3(x + 0.8, QUAY_Y + 6.2, LAMP_Z)
		add_child(lamp)
	# Palettes de caisses près des hangars.
	var wood := Color("#e0a955")
	for spot in PALLET_SPOTS:
		Blocks.box(self, Vector3(2.2, 0.25, 2.0), spot + Vector3(0, QUAY_Y + 0.125, 0), wood.darkened(0.3))
		Blocks.box(self, Vector3(2.0, 1.6, 1.8), spot + Vector3(0, QUAY_Y + 1.05, 0), wood)
		Blocks.box(self, Vector3(2.04, 0.12, 1.84), spot + Vector3(0, QUAY_Y + 1.2, 0), wood.darkened(0.2))
