# Briques de construction low-poly façon Globozone : matériaux unis et formes simples.
extends RefCounted

static var _materials := {}


# Matériau mat, partagé par couleur (et par intensité d'émission).
static func mat(color: Color, emission := 0.0) -> StandardMaterial3D:
	var key := [color, emission]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		if emission > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emission
		_materials[key] = m
	return _materials[key]


static func add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, emission)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add(parent, mesh, pos, color, emission)


static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return add(parent, mesh, pos, color)


# Câble tendu entre deux points (cordage, poteau incliné…).
static func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mi := cylinder(parent, radius, a.distance_to(b), (a + b) * 0.5, color, 6)
	mi.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	return mi


# Rectangle centré, dans le plan (x, z).
static func rect(width: float, depth: float) -> PackedVector2Array:
	var w := width * 0.5
	var d := depth * 0.5
	return PackedVector2Array([Vector2(-w, -d), Vector2(w, -d), Vector2(w, d), Vector2(-w, d)])


# Prisme vertical à partir d'un contour convexe (x, z), entre y0 et y1.
static func prism(outline: PackedVector2Array, y0: float, y1: float) -> ArrayMesh:
	return loft(outline, outline, y0, y1)


# Volume entre deux contours convexes de même nombre de sommets (tronc de pyramide…).
static func loft(bottom: PackedVector2Array, top: PackedVector2Array, y0: float, y1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := bottom.size()
	var centre := Vector2.ZERO
	for p in bottom:
		centre += p
	centre /= n
	var centre3 := Vector3(centre.x, (y0 + y1) * 0.5, centre.y)
	for i in range(1, n - 1):
		_tri(st, _v(top[0], y1), _v(top[i], y1), _v(top[i + 1], y1), Vector3.UP)
		_tri(st, _v(bottom[0], y0), _v(bottom[i], y0), _v(bottom[i + 1], y0), Vector3.DOWN)
	for i in n:
		var j := (i + 1) % n
		var a := _v(bottom[i], y0)
		var b := _v(bottom[j], y0)
		var c := _v(top[j], y1)
		var d := _v(top[i], y1)
		var normal := (b - a).cross(d - a).normalized()
		if normal.dot((a + b + c + d) * 0.25 - centre3) < 0.0:
			normal = -normal
		_tri(st, a, b, c, normal)
		_tri(st, a, c, d, normal)
	return st.commit()


static func _v(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


# Godot affiche les faces dont les sommets tournent dans le sens horaire vu de face.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(normal)
		st.add_vertex(v)
