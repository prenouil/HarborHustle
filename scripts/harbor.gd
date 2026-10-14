# Le port au départ : l'eau et un quai vide, avec un peu de mobilier.
# Le bord du quai longe z = 0, l'eau est côté +z. Les constantes décrivent le plan du quai.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")
const WATER_SHADER = preload("res://shaders/water.gdshader")

const QUAY_Y := 1.5
const QUAY_WIDTH := 270.0
const QUAY_DEPTH := 60.0
# Rails de la grue et voie des camions qui viennent se faire charger (vers -x).
const RAIL_ZS := [-4.0, -12.0]
const LANE_A_Z := -8.0
# Console de la grue, décalée par rapport à la grue.
const CONSOLE_OFFSET := Vector3(8.0, 0.0, -14.2)
# Voie de retour des camions (vers +x) et places de stationnement devant les hangars.
const LANE_B_Z := -17.0
const BAY_Z := -20.5
# Rangée des hangars : façade en z = HANGAR_FRONT_Z, centre en x limité à ±HANGAR_X_LIMIT.
const HANGAR_FRONT_Z := -26.0
const HANGAR_X_LIMIT := 63.0
# La grue doit rester en face du bateau.
const CRANE_X_LIMIT := 15.0
const BERTH := Vector3(0, 0, 8.6)
# Zone du quai où l'on peut marcher (x, z) : on reste à distance du bord.
const WALK_AREA := Rect2(-78, -58, 156, 56.8)

const BOLLARD_XS := [-42.0, -30.0, -18.0, -6.0, 6.0, 18.0, 30.0, 42.0]
const LAMP_XS := [-60.0, -20.0, 20.0, 60.0]
const LAMP_Z := -50.0
const PALLET_SPOTS := [Vector3(-70, 0, -52), Vector3(-67.4, 0, -52.3), Vector3(-40, 0, -54), Vector3(68, 0, -51)]

const CONCRETE := Color("#5d6a8c")
const PAVEMENT := Color("#4a5578")
const SAFETY := Color("#f2c230")


func _ready() -> void:
	_build_water()
	_build_quay()
	_build_props()


# Emprises au sol (x, z) du mobilier, que l'on ne peut pas traverser.
func obstacles() -> Array[Rect2]:
	var list: Array[Rect2] = []
	for x in BOLLARD_XS:
		list.append(Rect2(x - 0.5, -2.0, 1.0, 1.0))
	for x in LAMP_XS:
		list.append(Rect2(x - 0.2, LAMP_Z - 0.2, 0.4, 0.4))
	for spot in PALLET_SPOTS:
		list.append(Rect2(spot.x - 1.1, spot.z - 1.0, 2.2, 2.0))
	return list


# Amarre le bateau aux bollards ; renvoie les cordages, à passer à unmoor() au départ.
func moor(ship) -> Array[Node3D]:
	var lines := [
		[ship.cleat(27.0, -1), Vector3(42, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(20.0, -1), Vector3(30, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(-27.0, -1), Vector3(-42, QUAY_Y + 0.6, -1.5)],
		[ship.cleat(-20.0, -1), Vector3(-30, QUAY_Y + 0.6, -1.5)],
	]
	var ropes: Array[Node3D] = []
	for line in lines:
		ropes.append(Blocks.beam(self, ship.to_global(line[0]), line[1], 0.07, Color("#e8dcc0")))
	return ropes


func unmoor(ropes: Array[Node3D]) -> void:
	for rope in ropes:
		rope.queue_free()


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
	# Chaussée des camions, bande de sécurité et bord du quai.
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.02, 19), Vector3(0, QUAY_Y + 0.01, -12.5), PAVEMENT)
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.03, 0.5), Vector3(0, QUAY_Y + 0.015, -2.6), SAFETY)
	Blocks.box(self, Vector3(QUAY_WIDTH, 0.4, 0.8), Vector3(0, QUAY_Y + 0.05, -0.4), Color("#7b88a8"))
	for z in RAIL_ZS:
		Blocks.box(self, Vector3(QUAY_WIDTH, 0.06, 0.25), Vector3(0, QUAY_Y + 0.03, z), Color("#2a3150"))
	# Rangée des hangars : dalle plus claire.
	Blocks.box(self, Vector3(HANGAR_X_LIMIT * 2.0 + 32.0, 0.02, 20), Vector3(0, QUAY_Y + 0.012, HANGAR_FRONT_Z - 9.0), Color("#66739a"))
	var count := int(QUAY_WIDTH / 6.0)
	for i in count:
		var x := -QUAY_WIDTH * 0.5 + 3.0 + i * 6.0
		Blocks.box(self, Vector3(2.4, 0.05, 0.3), Vector3(x, QUAY_Y + 0.03, -15.0), Color("#d9dee8"))
		Blocks.box(self, Vector3(2.4, 0.05, 0.3), Vector3(x, QUAY_Y + 0.03, -22.2), SAFETY)
		# Défenses en caoutchouc sur la face du quai.
		Blocks.box(self, Vector3(1.2, 1.6, 0.5), Vector3(x + 3.0, 0.3, 0.2), Color("#1a1d26"))


func _build_props() -> void:
	for x in BOLLARD_XS:
		Blocks.cylinder(self, 0.35, 0.8, Vector3(x, QUAY_Y + 0.4, -1.5), Color("#1a1d26"))
		Blocks.cylinder(self, 0.5, 0.15, Vector3(x, QUAY_Y + 0.85, -1.5), Color("#1a1d26"))
	# Lampadaires, au fond du quai.
	for x in LAMP_XS:
		Blocks.box(self, Vector3(0.3, 7, 0.3), Vector3(x, QUAY_Y + 3.5, LAMP_Z), Color("#2a3150"))
		Blocks.box(self, Vector3(0.6, 0.3, 1.6), Vector3(x, QUAY_Y + 7.0, LAMP_Z + 0.6), Color("#2a3150"))
		Blocks.box(self, Vector3(0.45, 0.12, 1.2), Vector3(x, QUAY_Y + 6.82, LAMP_Z + 0.8), Color("#ffd8a0"), 3.0)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffcf8a")
		lamp.omni_range = 9.0
		lamp.light_energy = 1.2
		lamp.position = Vector3(x, QUAY_Y + 6.2, LAMP_Z + 0.8)
		add_child(lamp)
	# Palettes de caisses.
	var wood := Color("#e0a955")
	for spot in PALLET_SPOTS:
		Blocks.box(self, Vector3(2.2, 0.25, 2.0), spot + Vector3(0, QUAY_Y + 0.125, 0), wood.darkened(0.3))
		Blocks.box(self, Vector3(2.0, 1.6, 1.8), spot + Vector3(0, QUAY_Y + 1.05, 0), wood)
		Blocks.box(self, Vector3(2.04, 0.12, 1.84), spot + Vector3(0, QUAY_Y + 1.2, 0), wood.darkened(0.2))
