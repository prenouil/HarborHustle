# Scène principale : le port, l'argent du joueur, les constructions et les achats.
# Clic gauche au sol : le héros y va. Clic sur la console : il s'y rend et l'utilise.
# Pendant un placement, clic gauche : construire, Échap : annuler.
extends Node3D

const Harbor = preload("res://scripts/harbor.gd")
const Hangar = preload("res://scripts/hangar.gd")
const Crane = preload("res://scripts/crane.gd")
const Console = preload("res://scripts/console.gd")
const Character = preload("res://scripts/character.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")
const WalkMap = preload("res://scripts/walk_map.gd")
const Logistics = preload("res://scripts/logistics.gd")
const Construction = preload("res://scripts/construction.gd")
const Placement = preload("res://scripts/placement.gd")
const Hud = preload("res://scripts/hud.gd")

const START_MONEY := 100000
const PRICES := {"hangar": 2000, "crane": 1000, "truck": 1000, "docker": 100}
const NAMES := {"hangar": "Hangar", "crane": "Grue"}
const FIRST_SHIP_DELAY := 3.0

var money := START_MONEY
var harbor: Harbor
var hero: Character
var console: Console
var camera_rig: CameraRig
var walk_map: WalkMap
var logistics: Logistics
var construction: Construction
var placement: Placement
var hud: Hud

var _hero_locked := false
var _going_to_console := false
var _dialog_context := ""
# Emprise du bâtiment en chantier, à éviter pendant la construction.
var _site_rect := Rect2()


func _ready() -> void:
	randomize()
	_build_lighting()

	harbor = Harbor.new()
	add_child(harbor)

	hero = Character.new()
	hero.position = Vector3(4, Harbor.QUAY_Y, -20)
	hero.rotation_degrees.y = 25.0
	add_child(hero)
	hero.arrived.connect(_on_hero_arrived)

	logistics = Logistics.new(self, harbor)
	add_child(logistics)
	logistics.changed.connect(_refresh)

	construction = Construction.new()
	add_child(construction)

	placement = Placement.new()
	add_child(placement)

	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(2, Harbor.QUAY_Y, -10)
	add_child(camera_rig)

	hud = Hud.new()
	add_child(hud)
	hud.build_pressed.connect(_on_build_pressed)
	hud.vehicle_pressed.connect(_on_vehicle_pressed)
	hud.staff_pressed.connect(_on_staff_pressed)
	hud.dialog.chosen.connect(_on_dialog_chosen)

	_rebuild_walk_map()
	_refresh()
	_first_ship()


func _first_ship() -> void:
	await get_tree().create_timer(FIRST_SHIP_DELAY).timeout
	hud.toast("Un porte-containers arrive !")
	await logistics.spawn_ship()
	hud.toast("Le bateau est à quai, prêt à être déchargé.")


func _unhandled_input(event: InputEvent) -> void:
	if hud.dialog.visible:
		return
	if placement.active():
		if event is InputEventMouseMotion:
			_update_placement(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_update_placement(event.position)
			confirm_placement()
		elif event.is_action_pressed("ui_cancel"):
			cancel_placement()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_click(event.position)
	elif event is InputEventMouseMotion:
		var hover := not _hero_locked and _is_on_console(event.position)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover else Input.CURSOR_ARROW)


# --- Héros -------------------------------------------------------------------

func _on_click(screen: Vector2) -> void:
	if _hero_locked:
		return
	if _is_on_console(screen):
		_go_to(console.stand_point(), true)
	else:
		_go_to(camera_rig.ground_at(screen), false)


func _is_on_console(screen: Vector2) -> bool:
	if console == null:
		return false
	var camera: Camera3D = camera_rig.camera
	return console.hit_box().intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen)) != null


func _go_to(target: Vector3, to_console: bool) -> void:
	if _hero_locked:
		return
	var path := walk_map.find_path(Vector2(hero.position.x, hero.position.z), Vector2(target.x, target.z))
	if path.is_empty():
		return
	_going_to_console = to_console
	var points := _to_points(path)
	if points.is_empty():
		_on_hero_arrived()
		return
	hero.walk(points)
	if not to_console:
		_show_marker(points[points.size() - 1])


func _on_hero_arrived() -> void:
	if not _going_to_console:
		return
	_going_to_console = false
	hero.face(console.global_position - hero.position)
	_use_console()


func _to_points(path: PackedVector2Array) -> PackedVector3Array:
	var points := PackedVector3Array()
	for p in path.slice(1):
		points.append(Vector3(p.x, Harbor.QUAY_Y, p.y))
	return points


# --- Console de la grue ------------------------------------------------------

func _use_console() -> void:
	var title := "CONSOLE DE LA GRUE"
	if logistics.unloading:
		_open_dialog("info", title, "Déchargement en cours : %d containers encore à bord." % logistics.ship.containers.size(), ["Fermer"])
	elif not logistics.ship_ready():
		_open_dialog("info", title, "Aucun bateau à décharger pour le moment. Le prochain arrive bientôt.", ["Fermer"])
	elif not logistics.missing().is_empty():
		_open_dialog("info", title, "Un porte-containers attend, mais il manque %s pour le décharger." % " et ".join(logistics.missing()), ["Fermer"])
	else:
		_open_dialog("unload", title,
			"Un porte-containers est à quai, prêt à être déchargé.\n%d containers à bord.\n\nDécharger ?" % logistics.ship.containers.size(),
			["Oui", "Non"])


# --- Fenêtres ----------------------------------------------------------------

func _open_dialog(context: String, title: String, text: String, choices: Array, enabled: Array = []) -> void:
	_dialog_context = context
	hud.dialog.open(title, text, choices, enabled)


func _on_dialog_chosen(index: int) -> void:
	var context := _dialog_context
	_dialog_context = ""
	match context:
		"unload":
			if index == 0:
				logistics.start_unloading()
				hud.toast("Déchargement lancé.")
		"build":
			if index == 0:
				start_placement("hangar")
			elif index == 1:
				start_placement("crane")
		"truck":
			if index == 0:
				buy_truck()
		"docker":
			if index == 0:
				buy_docker()


func _on_build_pressed() -> void:
	if placement.active():
		cancel_placement()
		return
	var crane_taken := logistics.crane != null or construction.running or _hero_locked
	var crane_label := "Grue — %s" % Hud.format_money(PRICES.crane)
	if logistics.crane != null:
		crane_label = "Grue — déjà construite"
	_open_dialog("build", "BÂTIMENT", "Que voulez-vous construire ?",
		["Hangar — %s" % Hud.format_money(PRICES.hangar), crane_label, "Annuler"],
		[money >= PRICES.hangar, money >= PRICES.crane and not crane_taken, true])


func _on_vehicle_pressed() -> void:
	_open_dialog("truck", "VÉHICULE",
		"Camions : %d (%d au plus circulent en même temps).\n\nAcheter un camion pour %s ?" % [logistics.trucks.size(), Logistics.MAX_ACTIVE_TRUCKS, Hud.format_money(PRICES.truck)],
		["Acheter", "Fermer"], [money >= PRICES.truck, true])


func _on_staff_pressed() -> void:
	_open_dialog("docker", "PERSONNEL",
		"Dockers : %d (%d au plus travaillent en même temps).\n\nEmbaucher un docker pour %s ?" % [logistics.dockers.size(), Logistics.MAX_WORKING_DOCKERS, Hud.format_money(PRICES.docker)],
		["Embaucher", "Fermer"], [money >= PRICES.docker, true])


# --- Achats ------------------------------------------------------------------

func _spend(amount: int) -> bool:
	if money < amount:
		hud.toast("Fonds insuffisants.")
		return false
	money -= amount
	_refresh()
	return true


func buy_truck() -> void:
	if _spend(PRICES.truck):
		logistics.add_truck()
		hud.toast("Nouveau camion acheté.")


func buy_docker() -> void:
	if _spend(PRICES.docker):
		logistics.add_docker()
		hud.toast("Un docker rejoint l'équipe.")


# --- Placement et construction ----------------------------------------------

func start_placement(kind: String) -> void:
	placement.begin(kind)
	hud.set_hint("%s : clic gauche pour construire (%s)  ·  Échap pour annuler" % [NAMES[kind], Hud.format_money(PRICES[kind])])
	_update_placement(get_viewport().get_mouse_position())


func cancel_placement() -> void:
	placement.end()
	hud.set_hint("")


func _update_placement(screen: Vector2) -> void:
	update_placement(camera_rig.ground_at(screen))


func update_placement(ground: Vector3) -> void:
	var crane_taken := logistics.crane != null or construction.running
	placement.update(ground, _all_hangars(), crane_taken)


func confirm_placement() -> bool:
	if not placement.valid:
		hud.toast("Emplacement impossible.")
		return false
	if construction.running or _hero_locked:
		hud.toast("Un chantier est déjà en cours.")
		return false
	var kind := placement.kind
	if not _spend(PRICES[kind]):
		return false
	var at := placement.target
	cancel_placement()
	_build(kind, at)
	return true


func _all_hangars() -> Array:
	var list: Array = logistics.hangars.duplicate()
	for child in get_children():
		if child is Hangar and not list.has(child):
			list.append(child)
	return list


# Le héros se rend sur le chantier, puis le bâtiment pousse pendant 10 secondes.
# `instant` : bâtiment posé directement, sans chantier (pour les tests et les captures).
func _build(kind: String, at: Vector3, instant := false) -> void:
	_hero_locked = true
	_going_to_console = false
	var buildings: Array = []
	var stand: Vector3
	var focus: Vector3
	var hangar: Hangar
	var crane: Crane
	var new_console: Console
	if kind == "hangar":
		hangar = Hangar.new()
		hangar.letter = "ABCDEFGHIJ"[_all_hangars().size() % 10]
		hangar.position = at
		add_child(hangar)
		buildings = [hangar]
		_site_rect = hangar.footprint()
		stand = Vector3(at.x + 5.0, Harbor.QUAY_Y, at.z + 2.6)
		focus = Vector3(at.x, Harbor.QUAY_Y, at.z - Hangar.SIZE.z * 0.5)
	else:
		crane = Crane.new()
		crane.position = at
		add_child(crane)
		new_console = Console.new()
		new_console.position = at + Harbor.CONSOLE_OFFSET
		new_console.rotation.y = PI
		add_child(new_console)
		buildings = [crane, new_console]
		_site_rect = crane.footprint().merge(new_console.footprint())
		stand = Vector3(at.x - 3.0, Harbor.QUAY_Y, Harbor.CONSOLE_OFFSET.z - 1.0)
		focus = Vector3(at.x, Harbor.QUAY_Y, -8.0)
	if not instant:
		await _construct(buildings, stand, focus, NAMES[kind])

	_site_rect = Rect2()
	if kind == "hangar":
		logistics.hangars.append(hangar)
		logistics.refresh_rest_spots()
	else:
		logistics.crane = crane
		console = new_console
	_rebuild_walk_map()
	_hero_locked = false
	_refresh()
	if not instant:
		hud.toast("%s terminé%s !" % [NAMES[kind], "" if kind == "hangar" else "e"])


# Bâtiment posé tout de suite, sans chantier.
func build_now(kind: String, at: Vector3) -> void:
	_build(kind, at, true)


func _construct(buildings: Array, stand: Vector3, focus: Vector3, label: String) -> void:
	construction.prepare(buildings)
	_rebuild_walk_map()
	_refresh()
	hud.toast("Le héros part construire : %s." % label.to_lower())
	var points := _to_points(walk_map.find_path(Vector2(hero.position.x, hero.position.z), Vector2(stand.x, stand.z)))
	if not points.is_empty():
		hero.walk(points)
		await hero.arrived
	hero.face(focus - hero.position)
	hero.set_working(true)
	construction.run()
	await construction.finished
	hero.set_working(false)


func _rebuild_walk_map() -> void:
	var obstacles: Array[Rect2] = harbor.obstacles()
	for hangar in _all_hangars():
		obstacles.append(hangar.footprint())
	if console != null:
		obstacles.append(console.footprint())
	if _site_rect.has_area():
		obstacles.append(_site_rect)
	walk_map = WalkMap.new(Harbor.WALK_AREA, obstacles)
	logistics.walk_map = walk_map


# --- Affichage ---------------------------------------------------------------

func _refresh() -> void:
	hud.set_money(money)
	hud.set_counts(logistics.trucks.size(), logistics.dockers.size())
	hud.build_button.disabled = _hero_locked
	var ship_text := "aucun"
	if logistics.ship != null:
		if logistics.unloading:
			ship_text = "déchargement (%d à bord)" % logistics.ship.containers.size()
		elif logistics.ship.moored:
			ship_text = "à quai (%d containers)" % logistics.ship.containers.size()
		else:
			ship_text = "en approche"
	hud.set_status("Bateau : %s   ·   Stock : %d containers   ·   Dockers au travail : %d" % [ship_text, logistics.stock(), logistics.working_dockers()])
	if console != null:
		console.set_beacon(logistics.ship_ready() and not logistics.unloading)


# Repère au sol qui s'estompe, là où le héros se rend.
func _show_marker(at: Vector3) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.45
	mesh.outer_radius = 0.6
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#6fd3ff")
	material.emission_enabled = true
	material.emission = Color("#6fd3ff")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var marker := MeshInstance3D.new()
	marker.mesh = mesh
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.position = at + Vector3(0, 0.05, 0)
	marker.scale = Vector3(1, 0.3, 1)
	add_child(marker)
	var tween := marker.create_tween().set_parallel(true)
	tween.tween_property(marker, "scale", Vector3(2.0, 0.3, 2.0), 0.6)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.6)
	tween.chain().tween_callback(marker.queue_free)


func _build_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#10183a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8fa6e0")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -20, 0)
	sun.light_color = Color("#fff1dc")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)
