# Grue de quai (portique) : elle roule le long du quai sur ses rails (x),
# son chariot se déplace sur la flèche (z) et le palonnier monte et descend (y).
# Repère local : y = 0 au niveau du quai.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const YELLOW := Color("#f2c230")
const DARK := Color("#2a3150")
const WHITE := Color("#e8eef7")

const LEG_X := 5.0
const LEG_ZS := [-4.0, -12.0]
const PORTAL_Y := 20.0
const BOOM_Y := 24.0
const BOOM_FROM := -17.0
const BOOM_TO := 17.0
const BEAM_X := 1.8
# Hauteur du palonnier pendant les déplacements : au-dessus des piles du bateau.
const SAFE_Y := 14.0
const HOME_Z := -2.0
const CONTAINER_HALF := 1.3

const GANTRY_SPEED := 9.0
const TROLLEY_SPEED := 8.0
const HOIST_SPEED := 7.0

var trolley: Node3D
var spreader: Node3D
var _cables: Array[MeshInstance3D] = []
var _home_x := 0.0


func _ready() -> void:
	_home_x = position.x
	_build_frame()
	_build_trolley()
	_build_spreader()


func _process(_delta: float) -> void:
	_update_cables()


# Prend un container sur le bateau et le pose sur le camion.
func transfer(container: Node3D, truck) -> void:
	await _hoist(SAFE_Y)
	var pick := container.global_position
	await _travel(pick.x, pick.z)
	await _hoist(pick.y + CONTAINER_HALF - global_position.y)
	await get_tree().create_timer(0.25).timeout
	container.reparent(spreader)
	container.transform = Transform3D(Basis(), Vector3(0, -CONTAINER_HALF, 0))
	await _hoist(SAFE_Y)
	var drop: Vector3 = truck.next_slot_global()
	await _travel(drop.x, drop.z)
	await _hoist(drop.y + CONTAINER_HALF - global_position.y)
	await get_tree().create_timer(0.25).timeout
	truck.load_container(container)
	await _hoist(SAFE_Y)


# Retour en position de repos.
func park() -> void:
	await _hoist(SAFE_Y)
	await _travel(_home_x, HOME_Z)


func _travel(x: float, z: float) -> void:
	var dx := absf(x - position.x)
	var dz := absf(z - trolley.position.z)
	if dx < 0.01 and dz < 0.01:
		return
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:x", x, maxf(dx / GANTRY_SPEED, 0.2))
	var trolley_time := maxf(dz / TROLLEY_SPEED, 0.2)
	tween.tween_property(trolley, "position:z", z, trolley_time)
	tween.tween_property(spreader, "position:z", z, trolley_time)
	await tween.finished


func _hoist(y: float) -> void:
	var dy := absf(y - spreader.position.y)
	if dy < 0.01:
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(spreader, "position:y", y, maxf(dy / HOIST_SPEED, 0.2))
	await tween.finished


func _build_frame() -> void:
	for z in LEG_ZS:
		# Sommier à roues sur le rail, jambes, traverses.
		Blocks.box(self, Vector3(LEG_X * 2.0 + 2.0, 1.0, 1.4), Vector3(0, 0.5, z), DARK)
		for side in [-1, 1]:
			for dx in [-0.7, 0.7]:
				var wheel := Blocks.cylinder(self, 0.35, 1.5, Vector3(side * LEG_X + dx, 0.35, z), Color("#14151a"), 8)
				wheel.rotation.x = PI / 2
			Blocks.box(self, Vector3(1.0, PORTAL_Y - 1.0, 1.0), Vector3(side * LEG_X, (PORTAL_Y + 1.0) * 0.5, z), YELLOW)
			# Montants entre le portique et la flèche.
			Blocks.box(self, Vector3(0.7, BOOM_Y - PORTAL_Y, 0.7), Vector3(side * BEAM_X, (PORTAL_Y + BOOM_Y) * 0.5, z), YELLOW)
		Blocks.box(self, Vector3(LEG_X * 2.0 + 1.0, 1.2, 1.0), Vector3(0, PORTAL_Y, z), YELLOW)
		Blocks.box(self, Vector3(LEG_X * 2.0, 0.5, 0.5), Vector3(0, PORTAL_Y * 0.5, z), YELLOW)
	for side in [-1, 1]:
		var x: float = side * LEG_X
		Blocks.box(self, Vector3(1.0, 1.4, absf(LEG_ZS[1] - LEG_ZS[0]) + 1.0), Vector3(x, PORTAL_Y, (LEG_ZS[0] + LEG_ZS[1]) * 0.5), YELLOW)
		Blocks.beam(self, Vector3(x, 1.5, LEG_ZS[0]), Vector3(x, PORTAL_Y - 1.0, LEG_ZS[1]), 0.2, YELLOW)
		# Flèche : deux poutres le long de z.
		Blocks.box(self, Vector3(0.8, 1.4, BOOM_TO - BOOM_FROM), Vector3(side * BEAM_X, BOOM_Y, (BOOM_FROM + BOOM_TO) * 0.5), YELLOW)
		# Chevalet et haubans.
		var apex := Vector3(side * 1.2, BOOM_Y + 9.0, -8.0)
		Blocks.beam(self, Vector3(side * BEAM_X, BOOM_Y + 0.7, LEG_ZS[0]), apex, 0.3, YELLOW)
		Blocks.beam(self, Vector3(side * BEAM_X, BOOM_Y + 0.7, LEG_ZS[1]), apex, 0.3, YELLOW)
		Blocks.beam(self, apex, Vector3(side * BEAM_X, BOOM_Y + 0.7, BOOM_TO - 1.0), 0.12, DARK)
		Blocks.beam(self, apex, Vector3(side * BEAM_X, BOOM_Y + 0.7, 6.0), 0.12, DARK)
		Blocks.beam(self, apex, Vector3(side * BEAM_X, BOOM_Y + 0.7, BOOM_FROM + 1.0), 0.12, DARK)
	var z := BOOM_FROM + 1.0
	while z < BOOM_TO:
		Blocks.box(self, Vector3(BEAM_X * 2.0 + 0.8, 0.3, 0.3), Vector3(0, BOOM_Y + 0.75, z), YELLOW)
		z += 3.0
	# Salle des machines à l'arrière, feux en bout de flèche.
	Blocks.box(self, Vector3(5, 3, 6), Vector3(0, BOOM_Y + 2.2, BOOM_FROM + 3.0), WHITE)
	Blocks.box(self, Vector3(5.05, 0.5, 6.05), Vector3(0, BOOM_Y + 2.6, BOOM_FROM + 3.0), Color("#2f6fd6"))
	Blocks.box(self, Vector3(0.4, 0.4, 0.4), Vector3(0, BOOM_Y + 1.0, BOOM_TO - 0.3), Color("#ff3b30"), 3.0)
	Blocks.box(self, Vector3(0.4, 0.4, 0.4), Vector3(0, BOOM_Y + 9.4, -8.0), Color("#ff3b30"), 3.0)


func _build_trolley() -> void:
	trolley = Node3D.new()
	trolley.position = Vector3(0, BOOM_Y - 1.1, HOME_Z)
	add_child(trolley)
	Blocks.box(trolley, Vector3(4.4, 0.8, 3.0), Vector3.ZERO, DARK)
	# Cabine du grutier.
	Blocks.box(trolley, Vector3(2.2, 2.0, 2.2), Vector3(3.4, -1.0, 0), WHITE)
	Blocks.box(trolley, Vector3(2.0, 0.9, 2.26), Vector3(3.4, -0.8, 0), Color("#6fd3ff"), 0.6)
	for x in [-2.6, 2.6]:
		for z in [-0.9, 0.9]:
			var cable := Blocks.box(self, Vector3(0.08, 1.0, 0.08), Vector3(x, 0, z), Color("#14151a"))
			cable.set_meta("offset", Vector2(x, z))
			_cables.append(cable)


func _build_spreader() -> void:
	spreader = Node3D.new()
	spreader.position = Vector3(0, SAFE_Y, HOME_Z)
	add_child(spreader)
	Blocks.box(spreader, Vector3(6.2, 0.35, 0.5), Vector3(0, 0.2, -1.0), DARK)
	Blocks.box(spreader, Vector3(6.2, 0.35, 0.5), Vector3(0, 0.2, 1.0), DARK)
	Blocks.box(spreader, Vector3(1.0, 0.5, 2.5), Vector3(0, 0.3, 0), YELLOW)
	for x in [-2.9, 2.9]:
		Blocks.box(spreader, Vector3(0.5, 0.5, 2.5), Vector3(x, 0.25, 0), YELLOW)


func _update_cables() -> void:
	var top := trolley.position.y - 0.4
	var bottom := spreader.position.y + 0.45
	var length := maxf(top - bottom, 0.05)
	for cable in _cables:
		var offset: Vector2 = cable.get_meta("offset")
		cable.position = Vector3(offset.x, (top + bottom) * 0.5, trolley.position.z + offset.y)
		cable.scale = Vector3(1, length, 1)
