# Placement d'un bâtiment : un « fantôme » suit la souris, avec un carré au sol
# vert si l'emplacement convient, rouge sinon. La zone autorisée est surlignée.
extends Node3D

const Harbor = preload("res://scripts/harbor.gd")
const Hangar = preload("res://scripts/hangar.gd")
const Crane = preload("res://scripts/crane.gd")
const Console = preload("res://scripts/console.gd")

const OK_COLOR := Color(0.24, 0.86, 0.42, 0.5)
const BAD_COLOR := Color(0.9, 0.2, 0.2, 0.5)
# Écart minimal entre deux hangars.
const HANGAR_GAP := 1.0

# « hangar » ou « crane » ; vide quand aucun placement n'est en cours.
var kind := ""
var valid := false
# Position retenue pour le bâtiment (origine du hangar ou de la grue).
var target := Vector3.ZERO

var _ghost: Node3D
var _square: MeshInstance3D
var _square_material: StandardMaterial3D
var _zone: MeshInstance3D


func active() -> bool:
	return kind != ""


func begin(p_kind: String) -> void:
	end()
	kind = p_kind
	_ghost = Node3D.new()
	add_child(_ghost)
	if kind == "hangar":
		_ghost.add_child(Hangar.new())
	else:
		_ghost.add_child(Crane.new())
		var console := Console.new()
		console.position = Harbor.CONSOLE_OFFSET
		console.rotation.y = PI
		_ghost.add_child(console)
	_ghostify(_ghost)
	_square_material = _flat_material(OK_COLOR)
	_square = _flat(_square_material)
	var zone_rect := Rect2(-Harbor.HANGAR_X_LIMIT - Hangar.SIZE.x * 0.5, Harbor.HANGAR_FRONT_Z - Hangar.SIZE.z, Harbor.HANGAR_X_LIMIT * 2.0 + Hangar.SIZE.x, Hangar.SIZE.z)
	if kind == "crane":
		zone_rect = Rect2(-Harbor.CRANE_X_LIMIT - 6.0, -12.7, Harbor.CRANE_X_LIMIT * 2.0 + 12.0, 9.4)
	_zone = _flat(_flat_material(Color(1, 1, 1, 0.12)))
	_fit(_zone, zone_rect, 0.02)


func end() -> void:
	kind = ""
	valid = false
	for node in [_ghost, _square, _zone]:
		if node != null:
			node.queue_free()
	_ghost = null
	_square = null
	_zone = null


# Suit le point du sol visé par la souris. Près de la zone autorisée, le fantôme s'y aligne.
func update(ground: Vector3, hangars: Array, crane_taken: bool) -> void:
	var x := roundf(ground.x)
	var rect: Rect2
	if kind == "hangar":
		var near := ground.z < Harbor.HANGAR_FRONT_Z + 8.0 and ground.z > Harbor.HANGAR_FRONT_Z - Hangar.SIZE.z - 8.0
		var z := Harbor.HANGAR_FRONT_Z if near else roundf(ground.z + Hangar.SIZE.z * 0.5)
		target = Vector3(x, Harbor.QUAY_Y, z)
		rect = Rect2(x - Hangar.SIZE.x * 0.5, z - Hangar.SIZE.z, Hangar.SIZE.x, Hangar.SIZE.z)
		valid = near and absf(x) <= Harbor.HANGAR_X_LIMIT
		for hangar in hangars:
			if hangar.footprint().grow(HANGAR_GAP).intersects(rect):
				valid = false
	else:
		var near := ground.z > -18.0 and ground.z < 16.0
		var z := 0.0 if near else roundf(ground.z + 8.0)
		target = Vector3(x, Harbor.QUAY_Y, z)
		rect = Rect2(x - 6.0, z - 12.7, 12.0, 9.4)
		valid = near and absf(x) <= Harbor.CRANE_X_LIMIT and not crane_taken
	_ghost.position = target
	_fit(_square, rect, 0.05)
	_square_material.albedo_color = OK_COLOR if valid else BAD_COLOR


func _ghostify(node: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.9, 1.0, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for label: Label3D in node.find_children("*", "Label3D", true, false):
		label.hide()


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _flat(material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


func _fit(mesh: MeshInstance3D, rect: Rect2, height: float) -> void:
	mesh.mesh.size = Vector3(rect.size.x, 0.04, rect.size.y)
	var centre := rect.get_center()
	mesh.position = Vector3(centre.x, Harbor.QUAY_Y + height, centre.y)
