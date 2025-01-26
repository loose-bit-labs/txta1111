extends Node3D

@export var txtA111:TxtA1111
@export var texturable : Node3D

@export var prompt_edit :LineEdit
@export var negative_edit :LineEdit
@export var steps_edit :LineEdit
@export var resolution_edit :LineEdit
@export var generate :Button
@export var save_image :Button
@export var file_dialog :FileDialog
@export var mute :Button
@export var audio_player :AudioStreamPlayer3D
@export var music_credit :RichTextLabel
@export var bump_toggle :CheckBox
@export var bump_strength :HSlider
@export var bump_scale :HSlider
 
@export var clocko : Node3D

@export var strength_label :Label
@export var scale_label :Label
@export var bump :ColorRect
@export var bumped :MeshInstance3D
@export var subviewport :SubViewport
var viewport_texture :ViewportTexture = null
var bump_material : ShaderMaterial 

@export var use_common_material = true
var common_material :StandardMaterial3D = null
var materials : Array[StandardMaterial3D]
var current_image :ImageTexture
var current_normal :ImageTexture

static var CFG : String = "user://txt-a1111-demo.cfg"
@onready var CONFIGURABLE = [mute, prompt_edit, negative_edit, resolution_edit, bump_toggle, bump_strength, bump_scale];
var config :ConfigFile

func _ready() -> void:
	_materialistic()
	_load_config()
	file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	_on_button_pressed()

var __loading = false
func _load_config() -> void:
	config = ConfigFile.new()
	config.load(CFG)
	if not config.has_section("ui"):
		return
	for c in CONFIGURABLE:
		if config.has_section_key("ui", c.name):
			var v = config.get_value("ui", c.name) 
			if c is CheckBox:
				#c.toggle_mode = "Enable" == v # this breaks the checkbox
				pass
			elif c is Button or c is LineEdit:
				c.text = v
			else:
				c.value = v
	__loading = true
	_toggle_mute()
	_on_bump_toggled(bump_toggle.toggle_mode)
	_on_strength_value_changed(float(strength_label.text))
	_on_scale_value_changed(float(scale_label.text))
	__loading = false


func _save_config() -> void:
	if __loading == true:
		return
	for c in CONFIGURABLE:
		if c is LineEdit or c is Button: #c.text:
			config.set_value("ui", c.name, c.text)
		else:
			config.set_value("ui", c.name, c.value)
	config.save(CFG)


func _materialistic() -> void:
	if use_common_material:
		# one material to rule them all
		common_material = TxtA1111.same_material(texturable)
		common_material.albedo_color = Color.SLATE_BLUE
		common_material.albedo_texture = get_viewport().get_texture()
	else:
		# preserves existing textures and creates unique per mesh
		materials = TxtA1111.find_materials(texturable)
	_so_normal()


func _so_normal() -> void:
	bump_material = bump.material
	if false:
		viewport_texture = ViewportTexture.new()
		viewport_texture.resource_local_to_scene = true
		viewport_texture.viewport_path = subviewport.get_path()
	
	if common_material:
		common_material.normal_enabled = true
		common_material.normal_scale = 1.
		common_material.normal_texture = null
	else:
		for material in materials:
			material.normal_enabled = true
			material.normal_scale = 1.
			material.normal_texture = viewport_texture


func _on_button_pressed() -> void:
	generate.disabled = true
	clocko.visible = true
	var prompt = prompt_edit.text + txtA111.DEFAULT_PROMT_SUFFIX
	var negative = negative_edit.text
	var steps = int(steps_edit.text)
	var resolution = int(resolution_edit.text)
	_save_config()
	txtA111.run(prompt, negative, steps, resolution, resolution)


func _on_prompt_edit_text_submitted(_new_text: String) -> void:
	_on_button_pressed()


func _on_txt_a_1111_on_image(image: ImageTexture) -> void:
	current_image = image
	bump_material.set_shader_parameter("og", image)
	current_normal = image
	_delay_normal_update() # wait a sec....
	generate.disabled = false
	clocko.visible = false
	file_dialog.visible = false
	save_image.disabled = false
	_update_materials()

func _delay_normal_update():
	await get_tree().create_timer(0.131).timeout
	current_normal = ImageTexture.create_from_image(bumped.get_active_material(0).normal_texture.get_image())
	_update_materials()


func _update_materials():
	if common_material:
		_update_material(common_material, current_image, current_normal)
	else:
		for material in materials:
			_update_material(material, current_image, current_normal)


func _update_material(material:StandardMaterial3D, image:ImageTexture, normal:ImageTexture) -> StandardMaterial3D:
	material.albedo_color = Color.WHITE
	material.albedo_texture = image 
	material.normal_texture = normal
	return material


func _on_txt_a_1111_on_error(_message: String) -> void:
	generate.disabled = true
	clocko.visible = false
	file_dialog.visible = false
	if common_material:
		common_material.albedo_color = Color.RED


func _on_save_image_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(path: String) -> void:
	current_image.get_image().save_png(path)


func _toggle_mute() -> void:
	var value =  mute.text == "Mute"
	AudioServer.set_bus_mute(_get_sound_bus(), value)
	if value:
		mute.text = "Play ♫⋆.˚🎧 "
	else:
		mute.text = "Mute"
	music_credit.visible = !value
	audio_player.playing = !value
	_save_config()


func _get_sound_bus() -> int:
	return AudioServer.get_bus_index(audio_player.bus)


func _get_mute() -> bool:
	return AudioServer.is_bus_mute(_get_sound_bus()) 


func _on_bump_toggled(toggled_on: bool) -> void:
	if common_material:
		common_material.normal_enabled = toggled_on
	else:
		for material in materials:
			material.normal_enabled = toggled_on
	_save_config()


func _on_strength_value_changed(value: float) -> void:
	bump_material.set_shader_parameter("STRENGTH", value)
	strength_label.text = "%.0f" % value
	#current_normal = ImageTexture.create_from_image(bumped.get_active_material(0).normal_texture.get_image())
	_delay_normal_update()
	_save_config()


func _on_scale_value_changed(value: float) -> void:
	if common_material:
		common_material.normal_scale = value
	else:
		for material in materials:
			material.normal_scale = value
	scale_label.text = "%.2f" % value
	_save_config()
