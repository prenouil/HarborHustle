# Partie complète : quai vide, construction d'un hangar puis de la grue, achats,
# déchargement du premier bateau jusqu'au stock, puis arrivée du bateau suivant.
# Lancer : Godot --headless --path . --script res://tests/test_game.gd
extends SceneTree

const SPEED_UP := 25.0
# Délai maximal, en secondes de jeu (le delta reçu tient compte de time_scale).
const TIMEOUT := 4000.0
const Y := 1.5

var failures := 0
var _main: Node
var _step := 0
var _elapsed := 0.0
var _step_time := 0.0
var _cargo := 0
var _max_trucks := 0
var _max_working := 0
var _expected_money := 100000
var _build_started := 0.0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> bool:
	_elapsed += delta
	_step_time += delta
	if _main == null:
		_main = current_scene
		if _main == null:
			return false
		_check_start()
		Engine.time_scale = SPEED_UP
		return false
	_watch()
	match _step:
		0:
			_check_hangar_placement()
			_next()
		1:
			# Pendant le chantier, le héros n'obéit plus.
			if _step_time > 2.0 and _main.construction.running:
				var before: Vector3 = _main.hero.position
				_main._go_to(Vector3(-40, Y, -10), false)
				_expect(not _main.hero.is_walking() or _main.hero.position.distance_to(before) < 0.01 or _main._hero_locked, "le héros est bloqué pendant la construction")
				_expect(_main.hud.build_button.disabled, "bouton Bâtiment grisé pendant un chantier")
				_next()
		2:
			if not _main._hero_locked:
				_expect(_main.logistics.hangars.size() == 1, "le hangar est construit")
				_expect(_elapsed - _build_started >= 10.0, "la construction a duré au moins 10 s")
				_check_crane_placement()
				_next()
		3:
			if not _main._hero_locked:
				_expect(_main.logistics.crane != null and _main.console != null, "la grue et sa console sont construites")
				_main._go_to(_main.console.stand_point(), true)
				_next()
		4:
			if _main.hud.dialog.visible:
				_expect(_main._dialog_context == "info", "sans camion ni docker, la console refuse")
				_main.hud.dialog.choose(0)
				for i in 3:
					_main.buy_truck()
				for i in 3:
					_main.buy_docker()
				_expected_money -= 3 * 1000 + 3 * 100
				_expect(_main.money == _expected_money, "achats : %d €" % _main.money)
				_next()
		5:
			if _main.logistics.ship_ready() and _step_time > 5.0:
				_cargo = _main.logistics.ship.containers.size()
				_main._go_to(_main.console.stand_point(), true)
				_next()
		6:
			if _main.hud.dialog.visible:
				_expect(_main._dialog_context == "unload", "la console propose de décharger")
				_main.hud.dialog.choose(1)
				_expect(not _main.logistics.unloading, "Non ne lance rien")
				_main._go_to(_main.console.stand_point(), true)
				_next()
		7:
			if _main.hud.dialog.visible:
				_main.hud.dialog.choose(0)
				_expect(_main.logistics.unloading, "Oui lance le déchargement")
				_main._go_to(Vector3(-55, Y, -45), false)
				_next()
		8:
			if _main.logistics.ships_done == 1 and _main.logistics.stock() == _cargo and _all_trucks_idle():
				_expect(true, "%d containers rangés dans le hangar" % _cargo)
				_expect(_main.hero.position.distance_to(Vector3(-55, Y, -45)) < 1.0, "le héros reste libre pendant le déchargement")
				_expect(_max_trucks <= 2, "au plus 2 camions en circulation (vu %d)" % _max_trucks)
				_expect(_max_working <= 2, "au plus 2 dockers au travail (vu %d)" % _max_working)
				_expect(_max_working == 2, "2 dockers ont travaillé en même temps")
				_next()
		9:
			if _main.logistics.ship_ready():
				_expect(_main.logistics.ship.containers.size() > 0, "un nouveau bateau chargé est à quai")
				_expect(_main.money == _expected_money, "argent final : %d €" % _main.money)
				return _finish()
	if _elapsed > TIMEOUT:
		_expect(false, "délai dépassé à l'étape %d" % _step)
		return _finish()
	return false


func _next() -> void:
	_step += 1
	_step_time = 0.0


func _check_start() -> void:
	_expect(_main.money == 100000, "le joueur commence avec 100 000 €")
	_expect(_main.logistics.hangars.is_empty() and _main.logistics.crane == null, "le quai est vide")
	_expect(_main.logistics.trucks.is_empty() and _main.logistics.dockers.is_empty(), "ni camion ni docker")
	_expect(_main.hud.format_money(100000) == "100 000 €", "format de l'argent")


func _check_hangar_placement() -> void:
	_main.start_placement("hangar")
	_main.update_placement(Vector3(0, Y, 5))
	_expect(not _main.placement.valid, "pas de hangar dans l'eau")
	_main.update_placement(Vector3(0, Y, -10))
	_expect(not _main.placement.valid, "pas de hangar sur la voie des camions")
	_main.update_placement(Vector3(75, Y, -33))
	_expect(not _main.placement.valid, "pas de hangar qui déborde du quai")
	_main.update_placement(Vector3(10, Y, -33))
	_expect(_main.placement.valid, "hangar possible dans la rangée")
	_expect(_main.confirm_placement(), "hangar validé")
	_expected_money -= 2000
	_expect(_main.money == _expected_money, "hangar payé 2 000 €")
	_expect(_main._hero_locked, "le héros part construire")
	_build_started = _elapsed


func _check_crane_placement() -> void:
	_main.start_placement("hangar")
	_main.update_placement(Vector3(25, Y, -33))
	_expect(not _main.placement.valid, "deux hangars ne se chevauchent pas")
	_main.cancel_placement()
	_main.start_placement("crane")
	_main.update_placement(Vector3(0, Y, -35))
	_expect(not _main.placement.valid, "pas de grue loin du bateau")
	_main.update_placement(Vector3(40, Y, -8))
	_expect(not _main.placement.valid, "pas de grue hors de portée du bateau")
	_main.update_placement(Vector3(4, Y, -8))
	_expect(_main.placement.valid, "grue possible à côté du bateau")
	_expect(_main.confirm_placement(), "grue validée")
	_expected_money -= 1000
	_expect(_main.money == _expected_money, "grue payée 1 000 €")


func _watch() -> void:
	var on_screen := 0
	for truck in _main.logistics.trucks:
		if truck.visible:
			on_screen += 1
		if truck.cargo.size() > 4:
			_expect(false, "pas plus de 4 containers par camion")
	_max_trucks = maxi(_max_trucks, on_screen)
	_max_working = maxi(_max_working, _main.logistics.working_dockers())


func _all_trucks_idle() -> bool:
	for truck in _main.logistics.trucks:
		if truck.state != "idle":
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("ok   ", label)
	else:
		failures += 1
		print("ÉCHEC ", label)


func _finish() -> bool:
	Engine.time_scale = 1.0
	print("%d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
	return true
