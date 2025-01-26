shader_type canvas_item;

uniform sampler2D og : source_color;
uniform float BLUR = 3.;
uniform float STRENGTH = 24.;

vec4 raw_at(vec2 st, vec2 offset, vec2 size) {
    return texture(og, (st + offset) / size);
}

vec4 rgba_at(vec2 st, vec2 offset, vec2 size) {
	float sum = .0;
	vec4 accumulator = vec4(sum);
	for (float x = 1. ; x <= BLUR ; x++) {
		for (float y = 1. ; y <= BLUR ; y++) {
			vec2 blur_offset = vec2(x,y) * offset;
			float d = distance(blur_offset, offset);
			float weight = pow(1.33, d);
			sum += weight;
			vec4 color = raw_at(st, blur_offset, size);
			accumulator += weight * color;
		}
	}
	return accumulator / sum;
}

float value_at(vec2 st, vec2 offset, vec2 size) {
	vec4 v = rgba_at(st, offset, size);
	return (v.x + v.y + v.z) / 3.;
}

// Azagaya's Laighter is the gold standard
// this is hugely simplified but my favorite of the 4
// https://github.com/azagaya/godot_normalMap_generator
vec3 bumpLaighter(in vec2 st, in vec2 size, in vec3 o) {
	float x0 = value_at(st, o.xy, size);
	float x1 = value_at(st, o.zy, size);
	float y0 = value_at(st, o.yx, size);
	float y1 = value_at(st, o.yz, size);
    float dx = x0 - x1;
    float dy = y0 - y1;
    return normalize(vec3(dx * STRENGTH, dy * STRENGTH, 1.));
}

void fragment() {
	vec2 size = vec2(textureSize(og, 0));
	vec2 st = UV * size;
	vec3 o = vec3(-1,0,+1);
	COLOR.rgb = bumpLaighter(st, size, o);
}

void vertex() {}