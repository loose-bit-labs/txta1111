extends HTTPRequest
class_name TxtA1111

@export var URL                  = "http://192.168.0.202:7860/sdapi/v1/txt2img"
@export var DEFAULT_PROMPT_BASE  = "stone wall"
@export var DEFAULT_PROMT_SUFFIX = " texture <lora:DiffuseTexture_v11:1>, seamless"
@export var DEFAULT_NEGATIVE     = "blurry, watermark, out of focuse, cropped, missing limbs, extra limbs, ugly, waifu, hentai"
@export var DEFAULT_STEPS        = 22
@export var DEFAULT_WIDTH        = 256
@export var DEFAULT_HEIGHT       = 256

signal on_image(image:ImageTexture)
signal on_error(message:String)

func _ready() -> void:
	request_completed.connect(_on_response)


func run(
	prompt:String=DEFAULT_PROMPT_BASE + DEFAULT_PROMT_SUFFIX,
	negative:String=DEFAULT_NEGATIVE,
	steps:int=DEFAULT_STEPS,
	width:int=DEFAULT_WIDTH,
	height:int=DEFAULT_HEIGHT
) -> void:
	var headers = ["Content-Type: application/json"]
	var rrequest = JSON.stringify(make_request(prompt, negative, steps, width, height)) 
	var error = request(URL, headers, HTTPClient.METHOD_POST, rrequest)
	if error != OK:
		push_error("An error occurred in the _txta111 HTTP request.")
		on_error.emit("ouch!")


func make_request(prompt:String, negative:String, steps:int, width:int, height:int) -> Dictionary:
	return {"prompt":prompt, "negative": negative, "steps":steps, "width":width, "height":height}


func _on_response(result, response_code, headers, body) -> void:
	var text = body.get_string_from_utf8()
	var response = JSON.parse_string(text)
	if "images" in response:
		for base64_png in response.images:
			on_image.emit(png64_texture(base64_png))
	else:
		on_error.emit("error: %d ; %s ; %s ; %s", response_code, result, headers, text)


static func make_material(f:float = 3.) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.uv1_scale = Vector3(f,f,f)
	material.albedo_color = Color.RED
	material.resource_local_to_scene = true 
	return material


static func find_materials(node:Node, materials:Array[StandardMaterial3D] = []) -> Array[StandardMaterial3D]:
	if node is MeshInstance3D:
		var m3:MeshInstance3D = node as MeshInstance3D
		var active = m3.get_active_material(0)
		if active:
			active.resource_local_to_scene = true
			materials.append(active)
		else: 
			active = make_material()
			m3.set_surface_override_material(0, active)
		materials.append(active)
	for kid in node.get_children():
		find_materials(kid, materials)
	return materials

static func same_material(node:Node, material:StandardMaterial3D = null) -> StandardMaterial3D:
	if not material:
		material = make_material()
	if node is MeshInstance3D:
		var m3:MeshInstance3D = node as MeshInstance3D
		if m3:
			m3.set_surface_override_material(0, material)
			if m3.get_active_material(0):
				m3.get_active_material(0).resource_local_to_scene = true 
	for kid in node.get_children():
		same_material(kid, material)
	return material


static func png64_texture(base64_png) -> ImageTexture:
	var decoded_bytes = Marshalls.base64_to_raw(base64_png)
	var image = Image.new()
	var error = image.load_png_from_buffer(decoded_bytes)
	if error != OK:
		print("Error loading image: ", error)
		return null
	return ImageTexture.create_from_image(image)
