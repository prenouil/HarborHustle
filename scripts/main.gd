# Première scène : le bateau amarré, ses containers prêts à être déchargés,
# et le héros qui attend sur le quai devant les hangars.
extends Node3D

const Harbor = preload("res://scripts/harbor.gd")
const Ship = preload("res://scripts/ship.gd")
const Hero = preload("res://scripts/hero.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")

var harbor: Node3D
var ship: Node3D
var hero: Node3D
var camera_rig: Node3D


func _ready() -> void:
	_build_lighting()

	harbor = Harbor.new()
	add_child(harbor)

	ship = Ship.new()
	ship.position = Vector3(0, 0, 8.6)
	add_child(ship)
	harbor.moor(ship)

	hero = Hero.new()
	hero.position = Vector3(4, Harbor.QUAY_Y, -19)
	hero.rotation_degrees.y = 25.0
	hero.scale = Vector3.ONE * 1.3
	add_child(hero)

	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0, Harbor.QUAY_Y, -6)
	add_child(camera_rig)

	_build_hud()


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
	var title := Label.new()
	title.text = "HARBOR HUSTLE"
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f4f7fb"))
	title.add_theme_color_override("font_outline_color", Color("#10183a"))
	title.add_theme_constant_override("outline_size", 8)
	hud.add_child(title)
	var help := Label.new()
	help.text = "Molette : zoom   ·   Clic droit ou molette enfoncée : déplacer   ·   ZQSD / flèches : déplacer"
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 24
	help.offset_top = -44
	help.offset_bottom = -16
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color("#c9d6f2"))
	help.add_theme_color_override("font_outline_color", Color("#10183a"))
	help.add_theme_constant_override("outline_size", 6)
	hud.add_child(help)
