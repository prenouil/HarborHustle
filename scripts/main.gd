# Scène principale : le port, le bateau amarré, la grue, la console et le héros.
# Clic gauche au sol : le héros y va. Clic sur la console : il s'y rend et l'utilise.
extends Node3D

const Harbor = preload("res://scripts/harbor.gd")
const Ship = preload("res://scripts/ship.gd")
const Hero = preload("res://scripts/hero.gd")
const Crane = preload("res://scripts/crane.gd")
const Console = preload("res://scripts/console.gd")
const ConsoleDialog = preload("res://scripts/console_dialog.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")
const WalkMap = preload("res://scripts/walk_map.gd")
const Unloading = preload("res://scripts/unloading.gd")

var harbor: Harbor
var ship: Ship
var crane: Crane
var console: Console
var hero: Hero
var camera_rig: CameraRig
var walk_map: WalkMap
var unloading: Unloading
var dialog: ConsoleDialog

var _status: Label
var _going_to_console := false
var _asking_unload := false


func _ready() -> void:
	_build_lighting()

	harbor = Harbor.new()
	add_child(harbor)

	ship = Ship.new()
	ship.position = Vector3(0, 0, 8.6)
	add_child(ship)
	harbor.moor(ship)

	crane = Crane.new()
	crane.position = Vector3(0, Harbor.QUAY_Y, 0)
	add_child(crane)

	console = Console.new()
	console.position = Vector3(9, Harbor.QUAY_Y, -16)
	add_child(console)

	hero = Hero.new()
	hero.position = Vector3(4, Harbor.QUAY_Y, -19)
	hero.rotation_degrees.y = 25.0
	hero.scale = Vector3.ONE * 1.3
	add_child(hero)
	hero.arrived.connect(_on_hero_arrived)

	var obstacles: Array[Rect2] = harbor.obstacles()
	obstacles.append(console.footprint())
	walk_map = WalkMap.new(Harbor.WALK_AREA, obstacles)

	unloading = Unloading.new(ship, crane, Harbor.QUAY_Y)
	add_child(unloading)
	unloading.changed.connect(_update_status)

	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(2, Harbor.QUAY_Y, -2)
	add_child(camera_rig)

	_build_hud()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if dialog.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_click(event.position)
	elif event is InputEventMouseMotion:
		var hover := _is_on_console(event.position)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover else Input.CURSOR_ARROW)


func _on_click(screen: Vector2) -> void:
	if _is_on_console(screen):
		_go_to(console.stand_point(), true)
	else:
		_go_to(camera_rig.ground_at(screen), false)


func _is_on_console(screen: Vector2) -> bool:
	var camera: Camera3D = camera_rig.camera
	return console.hit_box().intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen)) != null


func _go_to(target: Vector3, to_console: bool) -> void:
	var path := walk_map.find_path(Vector2(hero.position.x, hero.position.z), Vector2(target.x, target.z))
	if path.is_empty():
		return
	_going_to_console = to_console
	var points := PackedVector3Array()
	for p in path.slice(1):
		points.append(Vector3(p.x, Harbor.QUAY_Y, p.y))
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


func _use_console() -> void:
	_asking_unload = false
	if unloading.running:
		dialog.inform("CONSOLE DE LA GRUE",
			"Déchargement en cours.\n%d containers encore à bord, %d camions déjà partis." % [unloading.remaining(), unloading.trucks_gone])
	elif unloading.remaining() == 0:
		dialog.inform("CONSOLE DE LA GRUE", "Aucun bateau à décharger pour le moment.")
	else:
		_asking_unload = true
		dialog.ask("CONSOLE DE LA GRUE",
			"Un porte-containers est à quai, prêt à être déchargé.\n%d containers à bord.\n\nDécharger ?" % unloading.remaining(),
			"Oui", "Non")


func _on_dialog_answered(yes: bool) -> void:
	if yes and _asking_unload:
		console.set_beacon(false)
		unloading.start()
	_asking_unload = false


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


func _update_status() -> void:
	var text := "Containers à bord : %d   ·   Camions partis : %d" % [unloading.remaining(), unloading.trucks_gone]
	if unloading.running:
		text += "   ·   Déchargement en cours"
	elif unloading.remaining() == 0:
		text += "   ·   Bateau déchargé"
	_status.text = text


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


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var title := _hud_label("HARBOR HUSTLE", 28, Color("#f4f7fb"))
	title.position = Vector2(24, 18)
	hud.add_child(title)
	_status = _hud_label("", 18, Color("#f2c230"))
	_status.position = Vector2(26, 58)
	hud.add_child(_status)
	var help := _hud_label("Clic gauche : déplacer le héros / utiliser la console   ·   Molette : zoom   ·   Clic droit ou ZQSD : déplacer la vue", 16, Color("#c9d6f2"))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 24
	help.offset_top = -44
	help.offset_bottom = -16
	hud.add_child(help)
	dialog = ConsoleDialog.new()
	dialog.answered.connect(_on_dialog_answered)
	hud.add_child(dialog)


func _hud_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#10183a"))
	label.add_theme_constant_override("outline_size", 6)
	return label
