# Scénario complet : le héros va à la console, accepte le déchargement,
# et la grue vide le bateau dans des camions de 4 containers.
# Lancer : Godot --headless --path . --script res://tests/test_unloading.gd
extends SceneTree

const SPEED_UP := 20.0
# Délai maximal, en secondes de jeu (le delta reçu tient compte de time_scale).
const TIMEOUT := 3000.0

var failures := 0
var _main: Node
var _step := 0
var _elapsed := 0.0
var _initial := 0
var _max_trucks_seen := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> bool:
	_elapsed += delta
	if _main == null:
		_main = current_scene
		if _main == null:
			return false
		_check_walk_map()
		_initial = _main.unloading.remaining()
		_expect(_initial > 0, "le bateau arrive chargé")
		_expect(_main.console.get_child(-1).visible, "la balise de la console est allumée")
		Engine.time_scale = SPEED_UP
		_main._go_to(_main.console.stand_point(), true)
		return false

	match _step:
		0:
			if _main.dialog.visible:
				_expect(_main.hero.position.distance_to(_main.console.stand_point()) < 0.1, "le héros est devant la console")
				_expect(_main._asking_unload, "la console propose de décharger")
				_main.dialog._answer(false)
				_expect(not _main.unloading.running, "Non ne lance rien")
				_main._go_to(_main.console.stand_point(), true)
				_step = 1
		1:
			if _main.dialog.visible:
				_main.dialog._answer(true)
				_expect(_main.unloading.running, "Oui lance le déchargement")
				# Le héros reste libre de ses mouvements pendant le déchargement.
				_main._go_to(Vector3(-50, 1.5, -50), false)
				_step = 2
		2:
			_max_trucks_seen = maxi(_max_trucks_seen, _trucks_on_quay())
			for truck in _trucks():
				if truck.cargo.size() > 4:
					_expect(false, "pas plus de 4 containers par camion")
			if not _main.unloading.running and _main.unloading.remaining() == 0:
				_expect(_main.hero.position.distance_to(Vector3(-50, 1.5, -50)) < 1.0, "le héros a pu aller derrière le hangar A")
				_step = 3
		3:
			# On laisse partir le dernier camion.
			if _trucks().is_empty():
				var expected := ceili(_initial / 4.0)
				_expect(_main.unloading.trucks_gone == expected, "%d camions partis (attendu %d)" % [_main.unloading.trucks_gone, expected])
				_expect(_max_trucks_seen <= 2, "au plus un camion qui part et un qui arrive")
				return _finish()
	if _elapsed > TIMEOUT:
		_expect(false, "délai dépassé à l'étape %d (%d containers à bord)" % [_step, _main.unloading.remaining()])
		return _finish()
	return false


func _check_walk_map() -> void:
	var map = _main.walk_map
	_expect(not map.is_walkable(Vector2(0, -30)), "on ne marche pas dans un hangar")
	_expect(not map.is_walkable(Vector2(0, 5)), "on ne marche pas dans l'eau")
	_expect(map.is_walkable(Vector2(0, -50)), "on peut marcher derrière les hangars")
	var path: PackedVector2Array = map.find_path(Vector2(4, -19), Vector2(0, -50))
	_expect(path.size() >= 3, "le chemin contourne le hangar")
	for i in path.size() - 1:
		_expect(map._is_clear(path[i], path[i + 1]), "segment %d praticable" % i)
	var clamped: PackedVector2Array = map.find_path(Vector2(4, -19), Vector2(4, 10))
	_expect(clamped[clamped.size() - 1].y < -1.0, "un clic dans l'eau s'arrête au bord du quai")


func _trucks() -> Array:
	var list := []
	for child in _main.get_children():
		if child.has_method("load_container"):
			list.append(child)
	return list


func _trucks_on_quay() -> int:
	return _trucks().size()


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
