# Déchargement du bateau : les camions se succèdent sous la grue, chacun reçoit
# jusqu'à 4 containers puis repart, jusqu'à ce que le bateau soit vide.
extends Node

signal changed
signal finished

const Truck = preload("res://scripts/truck.gd")

# Voie des camions, sous le portique de la grue.
const LANE_Z := -8.0
const PARK_X := 0.0
const ENTRY_X := 130.0
const EXIT_X := -130.0
const ARRIVE_TIME := 6.0
const LEAVE_TIME := 6.0
const CAB_COLORS := [Color("#d6402f"), Color("#2f6fd6"), Color("#e8e4da"), Color("#2bb3a8"), Color("#f08a24")]

var ship: Node3D
var crane: Node3D
var ground_y := 0.0

var running := false
var trucks_gone := 0


func _init(p_ship: Node3D, p_crane: Node3D, p_ground_y: float) -> void:
	ship = p_ship
	crane = p_crane
	ground_y = p_ground_y


func remaining() -> int:
	return ship.containers.size()


func start() -> void:
	if running or remaining() == 0:
		return
	running = true
	changed.emit()
	var count := 0
	while remaining() > 0:
		var truck := Truck.new()
		truck.cab_color = CAB_COLORS[count % CAB_COLORS.size()]
		truck.position = Vector3(ENTRY_X, ground_y, LANE_Z)
		ship.get_parent().add_child(truck)
		count += 1
		await truck.drive_to(PARK_X, ARRIVE_TIME)
		while not truck.is_full() and remaining() > 0:
			var container: Node3D = ship.containers.pop_front()
			changed.emit()
			await crane.transfer(container, truck)
		_send_away(truck)
	await crane.park()
	running = false
	changed.emit()
	finished.emit()


func _send_away(truck: Node3D) -> void:
	await truck.drive_away(EXIT_X, LEAVE_TIME)
	trucks_gone += 1
	changed.emit()
