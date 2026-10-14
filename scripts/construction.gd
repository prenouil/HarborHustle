# Chantier : fait apparaître des bâtiments du bas vers le haut.
# prepare() les rend invisibles tout de suite ; run() les fait pousser pendant DURATION secondes.
extends Node

signal finished

const REVEAL_SHADER = preload("res://shaders/build_reveal.gdshader")
const DURATION := 10.0

var running := false

var _swaps := []  # [MeshInstance3D, matériau d'origine]
var _shaders := {}  # matériau d'origine -> ShaderMaterial
var _labels: Array[Node] = []
var _bottom := 0.0
var _top := 0.0
var _elapsed := 0.0


func prepare(buildings: Array) -> void:
	_swaps.clear()
	_shaders.clear()
	_labels.clear()
	_bottom = INF
	_top = -INF
	for building in buildings:
		for mesh: MeshInstance3D in building.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			_bottom = minf(_bottom, box.position.y)
			_top = maxf(_top, box.end.y)
			var original: Material = mesh.material_override
			if not _shaders.has(original):
				_shaders[original] = _reveal_material(original)
			_swaps.append([mesh, original])
			mesh.material_override = _shaders[original]
		for label in building.find_children("*", "Label3D", true, false):
			label.hide()
			_labels.append(label)
	_set_reveal(_bottom - 1.0)


func run() -> void:
	running = true
	_elapsed = 0.0


func _process(delta: float) -> void:
	if not running:
		return
	_elapsed += delta
	var t := clampf(_elapsed / DURATION, 0.0, 1.0)
	_set_reveal(lerpf(_bottom, _top + 0.5, t))
	if t >= 1.0:
		running = false
		for swap in _swaps:
			if is_instance_valid(swap[0]):
				swap[0].material_override = swap[1]
		for label in _labels:
			label.show()
		finished.emit()


func _set_reveal(y: float) -> void:
	for material: ShaderMaterial in _shaders.values():
		material.set_shader_parameter("reveal_y", y)


func _reveal_material(original: Material) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = REVEAL_SHADER
	if original is StandardMaterial3D:
		material.set_shader_parameter("albedo", original.albedo_color)
		if original.emission_enabled:
			material.set_shader_parameter("emission_color", original.emission)
			material.set_shader_parameter("emission_energy", original.emission_energy_multiplier)
	return material
