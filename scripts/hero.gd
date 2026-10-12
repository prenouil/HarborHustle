# Le héros, en blocs façon Globozone : grosse tête trapézoïdale, cheveux et barbe noirs,
# chemise blanche à brassard rouge, cravate noire. Il regarde vers +z quand rotation.y = 0.
# Il suit les chemins qu'on lui donne, avec une marche simple (jambes et bras qui balancent).
extends Node3D

signal arrived

const Blocks = preload("res://scripts/blocks.gd")

const SPEED := 5.0
const SKIN := Color("#b08d6c")
const HAIR := Color("#14151a")
const SHIRT := Color("#e9eef5")
const PANTS := Color("#7c8590")
const NOSE := Color("#8f4b2e")
const RED := Color("#d23a33")

var _body: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _path := PackedVector3Array()
var _yaw := 0.0
var _stride := 0.0
var _phase := 0.0
var _time := 0.0


func _ready() -> void:
	_yaw = rotation.y
	_body = Node3D.new()
	add_child(_body)
	_build_body()
	_head = Node3D.new()
	_head.position = Vector3(0, 1.66, 0)
	_body.add_child(_head)
	_build_head()


func is_walking() -> bool:
	return not _path.is_empty()


# Suit les points dans l'ordre (coordonnées globales, sur le sol).
func walk(path: PackedVector3Array) -> void:
	_path = path


func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() > 0.01:
		_yaw = atan2(direction.x, direction.z)


func _process(delta: float) -> void:
	_time += delta
	if not _path.is_empty():
		var target := _path[0]
		var to := Vector3(target.x - position.x, 0, target.z - position.z)
		var step := SPEED * scale.x * delta / 1.3
		if to.length() <= step:
			position.x = target.x
			position.z = target.z
			_path.remove_at(0)
			if _path.is_empty():
				arrived.emit()
		else:
			position += to.normalized() * step
			_yaw = atan2(to.x, to.z)
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
	_arms[0].rotation.x = -swing * 0.5
	_arms[1].rotation.x = swing * 0.5
	var idle := 1.0 - _stride
	_body.position.y = absf(sin(_phase)) * 0.06 * _stride + sin(_time * 2.2) * 0.012 * idle
	# Attente : coups d'œil autour de lui.
	_head.rotation.y = (sin(_time * 0.5) * 0.35 + sin(_time * 1.3) * 0.05) * idle
	_head.rotation.x = sin(_time * 0.7) * 0.04 * idle


func _build_body() -> void:
	for side in [-1, 1]:
		# Jambe, articulée à la hanche.
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.2, 0.9, 0)
		_body.add_child(leg)
		_legs.append(leg)
		Blocks.box(leg, Vector3(0.3, 0.75, 0.32), Vector3(0, -0.375, 0), PANTS)
		Blocks.box(leg, Vector3(0.32, 0.15, 0.46), Vector3(0, -0.825, 0.05), HAIR)
		# Bras, articulé à l'épaule : manche, brassard, avant-bras, main.
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.53, 1.62, 0)
		_body.add_child(arm)
		_arms.append(arm)
		Blocks.box(arm, Vector3(0.26, 0.32, 0.32), Vector3(0, -0.12, 0), SHIRT)
		Blocks.box(arm, Vector3(0.02, 0.07, 0.2), Vector3(side * 0.135, -0.1, 0), RED)
		Blocks.box(arm, Vector3(0.22, 0.4, 0.26), Vector3(0, -0.47, 0), SKIN)
		Blocks.box(arm, Vector3(0.2, 0.18, 0.22), Vector3(0, -0.76, 0.02), SKIN)
	Blocks.box(_body, Vector3(0.8, 0.12, 0.42), Vector3(0, 0.96, 0), HAIR)
	Blocks.box(_body, Vector3(0.12, 0.09, 0.03), Vector3(0, 0.96, 0.215), Color("#9aa3ad"))
	Blocks.box(_body, Vector3(0.8, 0.66, 0.42), Vector3(0, 1.35, 0), SHIRT)
	# Cravate et badge.
	Blocks.box(_body, Vector3(0.1, 0.48, 0.03), Vector3(0, 1.36, 0.22), HAIR)
	Blocks.box(_body, Vector3(0.14, 0.08, 0.04), Vector3(0, 1.62, 0.22), HAIR)
	Blocks.box(_body, Vector3(0.14, 0.12, 0.03), Vector3(0.22, 1.5, 0.215), Color("#2f4f9e"))


func _build_head() -> void:
	var height := 0.95
	Blocks.add(_head, Blocks.loft(Blocks.rect(0.78, 0.7), Blocks.rect(0.62, 0.55), 0.0, height), Vector3.ZERO, SKIN)
	# Cheveux courts et bouclés.
	Blocks.box(_head, Vector3(0.68, 0.2, 0.6), Vector3(0, height + 0.06, -0.01), HAIR)
	for i in 5:
		Blocks.box(_head, Vector3(0.12, 0.06, 0.62), Vector3(-0.28 + i * 0.14, height + 0.16, -0.01), HAIR)
	# Barbe en collier.
	Blocks.box(_head, Vector3(0.82, 0.3, 0.12), Vector3(0, 0.15, 0.32), HAIR)
	Blocks.box(_head, Vector3(0.5, 0.12, 0.1), Vector3(0, 0.33, 0.31), HAIR)
	for side in [-1, 1]:
		Blocks.box(_head, Vector3(0.08, 0.48, 0.5), Vector3(side * 0.38, 0.24, 0.05), HAIR)
		# Oreilles.
		Blocks.box(_head, Vector3(0.07, 0.2, 0.12), Vector3(side * 0.37, 0.55, -0.05), SKIN)
		# Yeux, pupilles et sourcils.
		Blocks.box(_head, Vector3(0.19, 0.24, 0.03), Vector3(side * 0.15, 0.69, 0.3), Color.WHITE)
		Blocks.box(_head, Vector3(0.08, 0.1, 0.02), Vector3(side * 0.13, 0.65, 0.315), HAIR)
		Blocks.box(_head, Vector3(0.22, 0.06, 0.03), Vector3(side * 0.16, 0.85, 0.29), HAIR)
	# Bouche et nez.
	Blocks.box(_head, Vector3(0.14, 0.04, 0.02), Vector3(0, 0.42, 0.33), Color("#5b3a2a"))
	var nose := Blocks.box(_head, Vector3(0.14, 0.26, 0.2), Vector3(0, 0.58, 0.4), NOSE)
	nose.rotation.x = 0.45
