shader_type canvas_item;
uniform int region;
varying vec2 world;
varying vec4 tint;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	tint = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 p = floor(world);
	float d = 0.0;
	if (region == 0) {
		d = p.x - (972.0 + 20.0 * sin(p.y / 78.0));
	} else if (region == 1) {
		d = 171.0 + 19.0 * sin((p.y + 27.0) / 72.0) - p.x;
		p.x += 1152.0;
	} else {
		d = (1.0 - length((p - vec2(400.0, 378.0)) / vec2(141.0, 103.0))) * 113.0;
		if (p.y >= 446.0) d = max(d, 15.0 - abs(p.x - (447.0 + 19.0 * sin((p.y - 460.0) / 65.0))));
	}
	// Long broken strokes drift together down the river. Pond ripples move slowly.
	float rate = region == 2 ? 2.1 : 11.0;
	vec2 q = vec2(p.x, p.y - floor(TIME * rate));
	float bands = sin(q.y * 0.25 + sin(q.x * 0.067) * 1.16);
	float breaks = sin(q.x * .13 - q.y * .054) * sin(q.x * .067 + q.y * .091);
	float streak = smoothstep(.89, .99, bands) * smoothstep(.31, .86, breaks);
	float mask = smoothstep(1.0, 12.0, d);
	base.rgb = mix(base.rgb, vec3(.55, .82, .77), streak * mask * .21);
	COLOR = base * tint;
}

