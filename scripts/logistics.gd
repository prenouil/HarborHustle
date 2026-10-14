# Logistique du port : arrivée et départ des bateaux, va-et-vient des camions
# entre la grue et les hangars, travail des dockers.
#
# Circuit d'un camion : il attend hors de l'écran (côté +x de la voie A), vient sous la grue,
# reçoit jusqu'à 4 containers, sort par -x, revient par la voie B et se gare devant un hangar.
# Les dockers le vident avec leur transpalette, puis il repart par +x et redevient disponible.
extends Node

signal changed

const Harbor = preload("res://scripts/harbor.gd")
const Ship = preload("res://scripts/ship.gd")
const Truck = preload("res://scripts/truck.gd")
const Character = preload("res://scripts/character.gd")

const MAX_ACTIVE_TRUCKS := 2
const MAX_WORKING_DOCKERS := 2
const SHIP_FAR_X := 170.0
const SHIP_SAIL_TIME := 14.0
const NEXT_SHIP_DELAY := 6.0
const OFF_X := 130.0
# Le docker se place à cette distance de la place de stationnement pour glisser son transpalette.
const DOCKER_REACH := 4.15
const CAB_COLORS := [Color("#d6402f"), Color("#2f6fd6"), Color("#e8e4da"), Color("#2bb3a8"), Color("#f08a24")]
const SKINS := [Color("#b08d6c"), Color("#e0b48f"), Color("#8a5a3c"), Color("#c99a72")]

var world: Node3D
var harbor: Harbor
# Carte des déplacements à pied, remplacée quand le port change.
var walk_map
# Bateau à quai ou en approche (null entre deux bateaux).
var ship: Ship
var crane: Node3D
var hangars: Array[Node3D] = []
var trucks: Array[Node3D] = []
var dockers: Array[Node3D] = []
var unloading := false
var ships_done := 0

var _ropes: Array[Node3D] = []
var _working := 0
var _parked := {}  # hangar -> camion garé devant


func _init(p_world: Node3D, p_harbor: Harbor) -> void:
	world = p_world
	harbor = p_harbor


func ship_ready() -> bool:
	return ship != null and ship.moored and not ship.containers.is_empty()


func stock() -> int:
	var total := 0
	for hangar in hangars:
		total += hangar.stock
	return total


func working_dockers() -> int:
	return _working


# Ce qui manque pour lancer le déchargement.
func missing() -> PackedStringArray:
	var list := PackedStringArray()
	if hangars.is_empty():
		list.append("un hangar")
	if trucks.is_empty():
		list.append("un camion")
	if dockers.is_empty():
		list.append("un docker")
	return list


func spawn_ship() -> void:
	ship = Ship.new()
	ship.rng_seed = randi()
	ship.position = Harbor.BERTH - Vector3(SHIP_FAR_X, 0, 0)
	world.add_child(ship)
	changed.emit()
	await ship.sail_to(Harbor.BERTH.x, SHIP_SAIL_TIME, Tween.EASE_OUT)
	_ropes = harbor.moor(ship)
	ship.moored = true
	changed.emit()


func add_truck() -> void:
	var truck := Truck.new()
	truck.cab_color = CAB_COLORS[trucks.size() % CAB_COLORS.size()]
	truck.position = Vector3(OFF_X, Harbor.QUAY_Y, Harbor.LANE_A_Z)
	truck.visible = false
	world.add_child(truck)
	trucks.append(truck)
	changed.emit()


# Le docker arrive à pied par la gauche du quai et va attendre près des hangars.
func add_docker() -> void:
	var docker := Character.new()
	docker.look = "docker"
	docker.skin = SKINS[dockers.size() % SKINS.size()]
	docker.position = Vector3(Harbor.WALK_AREA.position.x + 1.0, Harbor.QUAY_Y, -20.0)
	docker.rotation.y = PI / 2
	world.add_child(docker)
	dockers.append(docker)
	_rest(docker)
	changed.emit()


# Renvoie les dockers inoccupés à leur place d'attente (après la construction d'un hangar).
func refresh_rest_spots() -> void:
	for docker in dockers:
		if not docker.busy:
			_rest(docker)


func start_unloading() -> void:
	if unloading or crane == null or not ship_ready() or not missing().is_empty():
		return
	unloading = true
	changed.emit()
	while not ship.containers.is_empty():
		var truck: Truck = await _idle_truck()
		truck.state = "to_crane"
		truck.position = Vector3(OFF_X, Harbor.QUAY_Y, Harbor.LANE_A_Z)
		truck.rotation.y = 0.0
		truck.show()
		await truck.drive(crane.home_x, 6.0, Tween.EASE_OUT)
		truck.state = "loading"
		while not truck.is_full() and not ship.containers.is_empty():
			var container: Node3D = ship.containers.pop_front()
			changed.emit()
			await crane.transfer(container, truck)
		_deliver(truck)
	await crane.park()
	unloading = false
	_send_ship_away()


func _send_ship_away() -> void:
	var leaving := ship
	ship = null
	leaving.moored = false
	harbor.unmoor(_ropes)
	_ropes.clear()
	ships_done += 1
	changed.emit()
	await leaving.sail_to(Harbor.BERTH.x + SHIP_FAR_X, SHIP_SAIL_TIME, Tween.EASE_IN)
	leaving.queue_free()
	await get_tree().create_timer(NEXT_SHIP_DELAY).timeout
	spawn_ship()


# Trajet d'un camion chargé : vers un hangar, déchargement par les dockers, retour au dépôt.
func _deliver(truck: Truck) -> void:
	truck.state = "to_hangar"
	await truck.drive(-OFF_X, 6.0, Tween.EASE_IN)
	truck.hide()
	var hangar: Node3D = await _free_hangar()
	_parked[hangar] = truck
	truck.position = Vector3(-OFF_X, Harbor.QUAY_Y, Harbor.LANE_B_Z)
	truck.rotation.y = PI
	truck.show()
	await truck.park(hangar.position.x, Harbor.BAY_Z, 8.0)
	truck.state = "unloading"
	while not truck.cargo.is_empty():
		var docker: Node3D = await _free_docker(hangar)
		var container: Node3D = truck.cargo.pop_back()
		truck.pending += 1
		_carry(docker, container, truck, hangar)
	while truck.pending > 0:
		await get_tree().process_frame
	_parked.erase(hangar)
	truck.state = "returning"
	await truck.leave(OFF_X, Harbor.LANE_B_Z, 6.0)
	truck.hide()
	truck.rotation.y = 0.0
	truck.position = Vector3(OFF_X, Harbor.QUAY_Y, Harbor.LANE_A_Z)
	truck.state = "idle"
	changed.emit()


# Un docker glisse son transpalette sous le container, le tire dans le hangar et revient.
func _carry(docker: Node3D, container: Node3D, truck: Truck, hangar: Node3D) -> void:
	docker.busy = true
	_working += 1
	changed.emit()
	var spot := Vector3(container.global_position.x, Harbor.QUAY_Y, Harbor.BAY_Z - DOCKER_REACH)
	await _walk_to(docker, spot)
	docker.face(Vector3.BACK)
	await get_tree().create_timer(0.3).timeout
	# Le container glisse du camion jusqu'au-dessus du transpalette, puis s'y pose.
	container.reparent(world)
	var rest: Vector3 = docker.jack_holder.global_position + Vector3(0, Truck.CONTAINER_SIZE.y * 0.5, 0)
	var tween := container.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(container, "global_position", Vector3(rest.x, container.global_position.y, rest.z), 0.6)
	tween.tween_property(container, "global_position", rest, 0.5)
	await tween.finished
	container.reparent(docker.jack_holder)
	container.transform = Transform3D(Basis(), Vector3(0, Truck.CONTAINER_SIZE.y * 0.5, 0))
	truck.pending -= 1
	# À reculons dans le hangar, en tirant le transpalette.
	docker.walk(PackedVector3Array([Vector3(spot.x, Harbor.QUAY_Y, hangar.position.z - 6.0)]), true)
	await docker.arrived
	container.queue_free()
	hangar.store()
	changed.emit()
	docker.walk(PackedVector3Array([spot]))
	await docker.arrived
	docker.busy = false
	_working -= 1
	changed.emit()
	_rest(docker)


func _idle_truck() -> Truck:
	while true:
		for truck in trucks.slice(0, MAX_ACTIVE_TRUCKS):
			if truck.state == "idle":
				return truck
		await get_tree().process_frame
	return null


# Le hangar libre le plus proche de la grue.
func _free_hangar() -> Node3D:
	while true:
		var best: Node3D = null
		for hangar in hangars:
			if _parked.has(hangar):
				continue
			if best == null or absf(hangar.position.x - crane.home_x) < absf(best.position.x - crane.home_x):
				best = hangar
		if best != null:
			return best
		await get_tree().process_frame
	return null


# Le docker inoccupé le plus proche du hangar, sans dépasser MAX_WORKING_DOCKERS au travail.
func _free_docker(hangar: Node3D) -> Node3D:
	while true:
		if _working < MAX_WORKING_DOCKERS:
			var best: Node3D = null
			for docker in dockers:
				if docker.busy:
					continue
				if best == null or docker.position.distance_to(hangar.position) < best.position.distance_to(hangar.position):
					best = docker
			if best != null:
				return best
		await get_tree().process_frame
	return null


# Place d'attente d'un docker : le long de la façade du premier hangar, sinon au fond du quai.
func _rest_spot(docker: Node3D) -> Vector3:
	var i := dockers.find(docker)
	var row := i / 6
	var column := i % 6
	if hangars.is_empty():
		return Vector3(-64.0 + column * 1.8, Harbor.QUAY_Y, -30.0 - row * 1.8)
	var hangar: Node3D = hangars[0]
	return Vector3(hangar.position.x - 14.0 + column * 1.8, Harbor.QUAY_Y, Harbor.HANGAR_FRONT_Z + 1.4 + row * 1.8)


func _rest(docker: Node3D) -> void:
	await _walk_to(docker, _rest_spot(docker))
	if not docker.busy:
		docker.face(Vector3.BACK)


func _walk_to(character: Node3D, target: Vector3) -> void:
	var path: PackedVector2Array = walk_map.find_path(Vector2(character.position.x, character.position.z), Vector2(target.x, target.z))
	var points := PackedVector3Array()
	for p in path.slice(1):
		points.append(Vector3(p.x, Harbor.QUAY_Y, p.y))
	if points.is_empty():
		return
	character.walk(points)
	await character.arrived
