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

@export var clocko : Node3D

var common_material :StandardMaterial3D= null
var current_image :ImageTexture

static var CFG : String = "user://txt-a1111-demo.cfg"
var config :ConfigFile

func _ready() -> void:
	_load_config()
	common_material = TxtA1111.same_material(texturable)
	common_material.albedo_color = Color.SLATE_BLUE
	common_material.albedo_texture = get_viewport().get_texture() #lul
	file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	_on_button_pressed()


func _on_button_pressed() -> void:
	generate.disabled = true
	clocko.visible = true
	var prompt = prompt_edit.text + txtA111.DEFAULT_PROMT_SUFFIX
	var negative = negative_edit.text
	var steps = int(steps_edit.text)
	var resolution = int(resolution_edit.text)
	config.set_value("ui", "prompt", prompt_edit.text)
	config.set_value("ui", "negative", negative_edit.text)
	config.set_value("ui", "resolution", resolution_edit.text)
	config.save(CFG)
	txtA111.run(prompt, negative, steps, resolution, resolution)


func _on_prompt_edit_text_submitted(_new_text: String) -> void:
	_on_button_pressed()


func _on_txt_a_1111_on_image(image: ImageTexture) -> void:
	generate.disabled = false
	clocko.visible = false
	file_dialog.visible = false
	save_image.disabled = false
	common_material.albedo_color = Color.WHITE
	common_material.albedo_texture = image
	current_image = image


func _on_txt_a_1111_on_error(_message: String) -> void:
	generate.disabled = true
	clocko.visible = false
	file_dialog.visible = false
	common_material.albedo_color = Color.RED


func _on_save_image_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(path: String) -> void:
	current_image.get_image().save_png(path)


func _load_config() -> void:
	config = ConfigFile.new()
	config.load(CFG)
	if config.has_section("ui"):
		if config.has_section_key("ui", "mute"):
			if config.get_value("ui", "mute"):
				mute.text = "Mute"
			else:
				mute.text = "Play"
			_toggle_mute()
		if config.has_section_key("ui", "prompt"):
			prompt_edit.text = config.get_value("ui", "prompt")
		if config.has_section_key("ui", "negative"):
			negative_edit.text = config.get_value("ui", "negative")
		if config.has_section_key("ui", "resolution"):
			resolution_edit.text  = config.get_value("ui", "resolution")
# Music by <a href="https://pixabay.com/users/robloxeur-43206746/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=245142">Mika Dupuis</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=245142">Pixabay</a>


func _toggle_mute() -> void:
	var value =  mute.text == "Mute"
	AudioServer.set_bus_mute(_get_sound_bus(), value)
	if value:
		mute.text = "Play ♫⋆.˚🎧 "
	else:
		mute.text = "Mute"
	music_credit.visible = !value
	audio_player.playing = !value
	config.set_value("ui", "mute", value)
	config.save(CFG)


func _get_sound_bus() -> int:
	return AudioServer.get_bus_index(audio_player.bus)


func _get_mute() -> bool:
	return AudioServer.is_bus_mute(_get_sound_bus()) 
