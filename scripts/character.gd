# Personnage en blocs façon Globozone : le héros (barbu à cravate) ou un docker
# (casque, gilet orange, transpalette). Il regarde vers +z quand rotation.y = 0
# et suit les chemins qu'on lui donne, avec une marche simple.
extends Node3D

signal arrived

const Blocks = preload("res://scripts/blocks.gd")

const MODEL_SCALE := 1.3
const SPEED := 5.0
const HAIR := Color("#14151a")
const SHIRT := Color("#e9eef5")
const PANTS := Color("#7c8590")
const NOSE := Color("#8f4b2e")
const RED := Color("#d23a33")
const VEST := Color("#f08a24")
const HELMET := Color("#f2c230")
const WORK_PANTS := Color("#2f3e63")

# « hero » ou « docker », à choisir avant l'ajout à la scène.
var look := "hero"
var skin := Color("#b08d6c")
# Docker : occupé à une tâche.
var busy := false
# Docker : point où se pose le container sur le transpalette.
var jack_holder: Node3D

var _model: Node3D
var _body: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _path := PackedVector3Array()
var _backwards := false
var _working := false
var _yaw := 0.0
var _stride := 0.0
var _phase := 0.0
var _time := 0.0


func _ready() -> void:
	_yaw = rotation.y
	_time = randf() * 10.0
	_model = Node3D.new()
	_model.scale = Vector3.ONE * MODEL_SCALE
	add_child(_model)
	_body = Node3D.new()
	_model.add_child(_body)
	_build_body()
	_head = Node3D.new()
	_head.position = Vector3(0, 1.66, 0)
	_body.add_child(_head)
	_build_head()
	if look == "docker":
		_build_jack()


func is_walking() -> bool:
	return not _path.is_empty()


# Suit les points dans l'ordre (coordonnées globales, sur le sol).
# À reculons, il garde le dos tourné vers sa destination (pour tirer le transpalette).
func walk(path: PackedVector3Array, backwards := false) -> void:
	_path = path
	_backwards = backwards


func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() > 0.01:
		_yaw = atan2(direction.x, direction.z)


# Gestes de chantier (coups de marteau), sur place.
func set_working(on: bool) -> void:
	_working = on


func _process(delta: float) -> void:
	_time += delta
	if not _path.is_empty():
		var target := _path[0]
		var to := Vector3(target.x - position.x, 0, target.z - position.z)
		var step := SPEED * delta
		if to.length() <= step:
			position.x = target.x
			position.z = target.z
			_path.remove_at(0)
			if _path.is_empty():
				arrived.emit()
		else:
			position += to.normalized() * step
			_yaw = atan2(to.x, to.z) + (PI if _backwards else 0.0)
	rotation.y = lerp_angle(rotation.y, _yaw, 1.0 - exp(-12.0 * delta))

	# Marche : balancement des membres, qui s'estompe à l'arrêt.
	_stride = move_toward(_stride, 1.0 if is_walking() else 0.0, delta * 6.0)
	if _stride > 0.0:
		_phase += delta * 10.0
	else:
		_phase = 0.0
	var swing := sin(_phase) * _stride
	_legs[0].rotation.x = swing * 0.6
	_legs[1].rotation.x = -swing * 0.6
	if jack_holder != null:
		# Les deux mains sur le timon du transpalette.
		_arms[0].rotation.x = -0.5
		_arms[1].rotation.x = -0.5
	elif _working:
		_arms[0].rotation.x = -0.4
		_arms[1].rotation.x = -1.7 + sin(_time * 14.0) * 0.6
	else:
		_arms[0].rotation.x = -swing * 0.5
		_arms[1].rotation.x = swing * 0.5
	var idle := 1.0 - _stride
	var work_bob := absf(sin(_time * 14.0)) * 0.03 if _working else 0.0
	_body.position.y = absf(sin(_phase)) * 0.06 * _stride + sin(_time * 2.2) * 0.012 * idle + work_bob
	# Attente : coups d'œil autour de lui.
	var look_around := 0.0 if _working else idle
	_head.rotation.y = (sin(_time * 0.5) * 0.35 + sin(_time * 1.3) * 0.05) * look_around
	_head.rotation.x = sin(_time * 0.7) * 0.04 * look_around + (0.25 if _working else 0.0)


func _build_body() -> void:
	var docker := look == "docker"
	var pants := WORK_PANTS if docker else PANTS
	var shirt := Color("#c9d6f2") if docker else SHIRT
	for side in [-1, 1]:
		# Jambe, articulée à la hanche.
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.2, 0.9, 0)
		_body.add_child(leg)
		_legs.append(leg)
		Blocks.box(leg, Vector3(0.3, 0.75, 0.32), Vector3(0, -0.375, 0), pants)
		Blocks.box(leg, Vector3(0.32, 0.15, 0.46), Vector3(0, -0.825, 0.05), HAIR)
		# Bras, articulé à l'épaule : manche, brassard, avant-bras, main.
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.53, 1.62, 0)
		_body.add_child(arm)
		_arms.append(arm)
		Blocks.box(arm, Vector3(0.26, 0.32, 0.32), Vector3(0, -0.12, 0), shirt)
		if not docker:
			Blocks.box(arm, Vector3(0.02, 0.07, 0.2), Vector3(side * 0.135, -0.1, 0), RED)
		Blocks.box(arm, Vector3(0.22, 0.4, 0.26), Vector3(0, -0.47, 0), skin)
		Blocks.box(arm, Vector3(0.2, 0.18, 0.22), Vector3(0, -0.76, 0.02), skin)
	Blocks.box(_body, Vector3(0.8, 0.12, 0.42), Vector3(0, 0.96, 0), HAIR)
	Blocks.box(_body, Vector3(0.12, 0.09, 0.03), Vector3(0, 0.96, 0.215), Color("#9aa3ad"))
	Blocks.box(_body, Vector3(0.8, 0.66, 0.42), Vector3(0, 1.35, 0), shirt)
	if docker:
		# Gilet orange à bandes réfléchissantes.
		Blocks.box(_body, Vector3(0.84, 0.6, 0.46), Vector3(0, 1.36, 0), VEST)
		Blocks.box(_body, Vector3(0.86, 0.07, 0.48), Vector3(0, 1.22, 0), Color("#e8eef7"))
		Blocks.box(_body, Vector3(0.86, 0.07, 0.48), Vector3(0, 1.44, 0), Color("#e8eef7"))
	else:
		# Cravate et badge.
		Blocks.box(_body, Vector3(0.1, 0.48, 0.03), Vector3(0, 1.36, 0.22), HAIR)
		Blocks.box(_body, Vector3(0.14, 0.08, 0.04), Vector3(0, 1.62, 0.22), HAIR)
		Blocks.box(_body, Vector3(0.14, 0.12, 0.03), Vector3(0.22, 1.5, 0.215), Color("#2f4f9e"))


func _build_head() -> void:
	var height := 0.95
	Blocks.add(_head, Blocks.loft(Blocks.rect(0.78, 0.7), Blocks.rect(0.62, 0.55), 0.0, height), Vector3.ZERO, skin)
	if look == "docker":
		# Casque de chantier et moustache.
		Blocks.box(_head, Vector3(0.7, 0.24, 0.62), Vector3(0, height + 0.08, -0.01), HELMET)
		Blocks.box(_head, Vector3(0.78, 0.05, 0.74), Vector3(0, height - 0.02, 0.04), HELMET)
		Blocks.box(_head, Vector3(0.36, 0.08, 0.06), Vector3(0, 0.4, 0.34), HAIR)
	else:
		# Cheveux courts et bouclés, barbe en collier.
		Blocks.box(_head, Vector3(0.68, 0.2, 0.6), Vector3(0, height + 0.06, -0.01), HAIR)
		for i in 5:
			Blocks.box(_head, Vector3(0.12, 0.06, 0.62), Vector3(-0.28 + i * 0.14, height + 0.16, -0.01), HAIR)
		Blocks.box(_head, Vector3(0.82, 0.3, 0.12), Vector3(0, 0.15, 0.32), HAIR)
		Blocks.box(_head, Vector3(0.5, 0.12, 0.1), Vector3(0, 0.33, 0.31), HAIR)
		for side in [-1, 1]:
			Blocks.box(_head, Vector3(0.08, 0.48, 0.5), Vector3(side * 0.38, 0.24, 0.05), HAIR)
	for side in [-1, 1]:
		# Oreilles.
		Blocks.box(_head, Vector3(0.07, 0.2, 0.12), Vector3(side * 0.37, 0.55, -0.05), skin)
		# Yeux, pupilles et sourcils.
		Blocks.box(_head, Vector3(0.19, 0.24, 0.03), Vector3(side * 0.15, 0.69, 0.3), Color.WHITE)
		Blocks.box(_head, Vector3(0.08, 0.1, 0.02), Vector3(side * 0.13, 0.65, 0.315), HAIR)
		Blocks.box(_head, Vector3(0.22, 0.06, 0.03), Vector3(side * 0.16, 0.85, 0.29), HAIR)
	# Bouche et nez.
	Blocks.box(_head, Vector3(0.14, 0.04, 0.02), Vector3(0, 0.42, 0.33), Color("#5b3a2a"))
	var nose := Blocks.box(_head, Vector3(0.14, 0.26, 0.2), Vector3(0, 0.58, 0.4), NOSE)
	nose.rotation.x = 0.45


# Transpalette poussé devant le docker (en mètres réels, hors de l'échelle du modèle).
func _build_jack() -> void:
	var red := Color("#d6402f")
	var steel := Color("#3d4a70")
	for x in [-0.5, 0.5]:
		Blocks.box(self, Vector3(0.3, 0.12, 2.3), Vector3(x, 0.12, 1.75), steel)
		Blocks.box(self, Vector3(0.18, 0.14, 0.18), Vector3(x, 0.07, 2.75), Color("#14151a"))
	Blocks.box(self, Vector3(1.3, 0.45, 0.35), Vector3(0, 0.3, 0.55), red)
	Blocks.beam(self, Vector3(0, 0.5, 0.55), Vector3(0, 1.15, 0.3), 0.05, Color("#14151a"))
	Blocks.box(self, Vector3(0.5, 0.06, 0.06), Vector3(0, 1.15, 0.3), Color("#14151a"))
	jack_holder = Node3D.new()
	jack_holder.position = Vector3(0, 0.18, 1.75)
	add_child(jack_holder)
