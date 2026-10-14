# Fenêtre modale : un titre, un texte et une rangée de boutons.
# Le dernier bouton sert à fermer / refuser (style neutre). Échap revient à le choisir.
# Elle bloque les clics sur le jeu tant qu'elle est ouverte.
extends Control

signal chosen(index: int)

const BACKGROUND := Color("#17224a")
const ACCENT := Color("#6fd3ff")
const PRIMARY := Color("#2f9e5a")
const NEUTRAL := Color("#3d4a70")

var _title: Label
var _text: Label
var _buttons: HBoxContainer
var _cancel_index := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.12, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.border_color = ACCENT
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", ACCENT)
	box.add_child(_title)
	_text = Label.new()
	_text.custom_minimum_size = Vector2(460, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color("#e8eef7"))
	box.add_child(_text)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 18)
	box.add_child(_buttons)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		choose(_cancel_index)


# Ouvre la fenêtre. `enabled` (facultatif) grise les choix impossibles.
func open(title: String, text: String, choices: Array, enabled: Array = []) -> void:
	_title.text = title
	_text.text = text
	for child in _buttons.get_children():
		child.queue_free()
	_cancel_index = choices.size() - 1
	for i in choices.size():
		var button := _button(choices[i], NEUTRAL if i == _cancel_index else PRIMARY)
		button.disabled = i < enabled.size() and not enabled[i]
		button.pressed.connect(choose.bind(i))
		_buttons.add_child(button)
	show()


func choose(index: int) -> void:
	hide()
	chosen.emit(index)


func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_disabled_color", Color("#7f8aa8"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		match state:
			"hover":
				style.bg_color = color.lightened(0.15)
			"pressed":
				style.bg_color = color.darkened(0.15)
			"disabled":
				style.bg_color = Color("#2a3150")
			"focus":
				style.draw_center = false
				style.border_color = ACCENT
				style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(10)
		button.add_theme_stylebox_override(state, style)
	return button
