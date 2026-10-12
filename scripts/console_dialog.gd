# Fenêtre de la console : une question (Oui / Non) ou une simple information (Fermer).
# Elle bloque les clics sur le jeu tant qu'elle est ouverte.
extends Control

signal answered(yes: bool)

const BACKGROUND := Color("#17224a")
const ACCENT := Color("#6fd3ff")

var _title: Label
var _text: Label
var _yes: Button
var _no: Button


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
	_text.custom_minimum_size = Vector2(440, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color("#e8eef7"))
	box.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	_yes = _button(Color("#2f9e5a"))
	_yes.pressed.connect(_answer.bind(true))
	buttons.add_child(_yes)
	_no = _button(Color("#3d4a70"))
	_no.pressed.connect(_answer.bind(false))
	buttons.add_child(_no)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func ask(title: String, text: String, yes_text: String, no_text: String) -> void:
	_open(title, text)
	_yes.text = yes_text
	_yes.show()
	_no.text = no_text


func inform(title: String, text: String) -> void:
	_open(title, text)
	_yes.hide()
	_no.text = "Fermer"


func _open(title: String, text: String) -> void:
	_title.text = title
	_text.text = text
	show()


func _answer(yes: bool) -> void:
	hide()
	answered.emit(yes)


func _button(color: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 46)
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.lightened(0.15) if state == "hover" else color.darkened(0.15) if state == "pressed" else color
		style.set_corner_radius_all(6)
		if state == "focus":
			style.draw_center = false
			style.border_color = ACCENT
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	return button
