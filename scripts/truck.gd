# Camion porte-containers : il roule vers -x, reçoit 4 containers (2 de long, 2 de haut) puis repart.
# Repère local : origine au centre de la remorque, au niveau du sol ; la cabine est côté -x.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const CAPACITY := 4
const BED_Y := 1.4
const CONTAINER_SIZE := Vector3(6.0, 2.6, 2.4)
const SLOT_XS := [-3.1, 3.1]

var cargo: Array[Node3D] = []
var cab_color := Color("#d6402f")


func _ready() -> void:
	_build()


func is_full() -> bool:
	return cargo.size() >= CAPACITY


# Position (globale) du centre du prochain container à charger : d'abord le rang du bas, cabine en premier.
func next_slot_global() -> Vector3:
	return to_global(_slot(cargo.size()))


func load_container(container: Node3D) -> void:
	container.reparent(self)
	container.transform = Transform3D(Basis(), _slot(cargo.size()))
	cargo.append(container)


func drive_to(x: float, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", x, duration)
	await tween.finished


# Démarre, sort de l'écran et disparaît avec son chargement.
func drive_away(x: float, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", x, duration)
	await tween.finished
	queue_free()


func _slot(i: int) -> Vector3:
	return Vector3(SLOT_XS[i % 2], BED_Y + CONTAINER_SIZE.y * (0.5 + (1 if i >= 2 else 0)), 0)


func _build() -> void:
	var dark := Color("#2a3150")
	var tyre := Color("#14151a")
	# Remorque plateau.
	Blocks.box(self, Vector3(13.0, 0.3, 2.5), Vector3(0, BED_Y - 0.15, 0), dark)
	Blocks.box(self, Vector3(13.0, 0.4, 0.3), Vector3(0, BED_Y - 0.5, -0.9), dark)
	Blocks.box(self, Vector3(13.0, 0.4, 0.3), Vector3(0, BED_Y - 0.5, 0.9), dark)
	Blocks.box(self, Vector3(0.2, 0.3, 2.5), Vector3(6.4, BED_Y - 0.4, 0), Color("#ff3b30"), 1.5)
	for x in [3.6, 4.7, 5.8]:
		for z in [-1.0, 1.0]:
			Blocks.box(self, Vector3(1.0, 1.0, 0.45), Vector3(x, 0.5, z), tyre)
	# Tracteur.
	Blocks.box(self, Vector3(4.2, 0.5, 2.3), Vector3(-7.6, 0.9, 0), dark)
	Blocks.box(self, Vector3(2.6, 2.6, 2.5), Vector3(-8.6, 2.3, 0), cab_color)
	Blocks.box(self, Vector3(2.0, 0.6, 2.4), Vector3(-8.3, 3.9, 0), cab_color.darkened(0.2))
	Blocks.box(self, Vector3(0.06, 1.0, 2.1), Vector3(-9.92, 2.7, 0), Color("#6fd3ff"), 0.4)
	Blocks.box(self, Vector3(0.3, 0.4, 2.6), Vector3(-9.95, 0.9, 0), Color("#9aa3ad"))
	for z in [-0.9, 0.9]:
		Blocks.box(self, Vector3(0.06, 0.25, 0.4), Vector3(-9.92, 1.5, z), Color("#fff4d0"), 3.0)
	for x in [-9.0, -6.6, -5.5]:
		for z in [-1.0, 1.0]:
			Blocks.box(self, Vector3(1.0, 1.0, 0.45), Vector3(x, 0.5, z), tyre)
