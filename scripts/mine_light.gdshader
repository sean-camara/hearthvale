shader_type canvas_item;

uniform vec2 player;
uniform bool lantern_on;
uniform float chamber;
varying vec2 world;

void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
	float radius=lantern_on ? 228.0 : 131.0;
	float d=distance(player-world,vec2(0.,-14.));
	float veil=smoothstep(radius*.25,radius,d) * (.49+chamber*.045);
	COLOR=vec4(.075,.081,.117,veil);
}
