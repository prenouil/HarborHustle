# Le héros, en blocs façon Globozone : grosse tête trapézoïdale, cheveux et barbe noirs,
# chemise blanche à brassard rouge, cravate noire. Il regarde vers +z.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const SKIN := Color("#b08d6c")
const HAIR := Color("#14151a")
const SHIRT := Color("#e9eef5")
const PANTS := Color("#7c8590")
const NOSE := Color("#8f4b2e")
const RED := Color("#d23a33")

var _head: Node3D
var _body: Node3D
var _time := 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_build_body()
	_head = Node3D.new()
	_head.position = Vector3(0, 1.66, 0)
	_body.add_child(_head)
	_build_head()


func _process(delta: float) -> void:
	# Attente : respiration et coups d'œil vers le bateau.
	_time += delta
	_body.position.y = sin(_time * 2.2) * 0.012
	_head.rotation.y = sin(_time * 0.5) * 0.35 + sin(_time * 1.3) * 0.05
	_head.rotation.x = sin(_time * 0.7) * 0.04


func _build_body() -> void:
	for side in [-1, 1]:
		Blocks.box(_body, Vector3(0.32, 0.15, 0.46), Vector3(side * 0.2, 0.075, 0.05), HAIR)
		Blocks.box(_body, Vector3(0.3, 0.75, 0.32), Vector3(side * 0.2, 0.525, 0), PANTS)
		# Bras : manche, brassard, avant-bras, main.
		Blocks.box(_body, Vector3(0.26, 0.32, 0.32), Vector3(side * 0.53, 1.5, 0), SHIRT)
		Blocks.box(_body, Vector3(0.02, 0.07, 0.2), Vector3(side * 0.665, 1.52, 0), RED)
		Blocks.box(_body, Vector3(0.22, 0.4, 0.26), Vector3(side * 0.53, 1.15, 0), SKIN)
		Blocks.box(_body, Vector3(0.2, 0.18, 0.22), Vector3(side * 0.53, 0.86, 0.02), SKIN)
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
