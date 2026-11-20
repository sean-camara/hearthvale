shader_type canvas_item;
uniform int season : hint_range(0, 7);
uniform bool canopy = false;
uniform bool meadow = false;
varying vec4 lighting;

void vertex() {
	lighting=COLOR;
}

void fragment() {
	vec4 src=texture(TEXTURE,UV);
	vec3 c=src.rgb;
	float lum=dot(c,vec3(0.24,0.61,0.15));
	bool green=c.g>c.r*0.90 && c.g>c.b*1.12;
	bool blossom=canopy && c.r>c.g*1.14 && c.b>c.g*.88;
	if ((green || blossom || meadow) && season>0) {
		vec3 tone=c;
		if (season==1) tone=c*vec3(1.05,1.04,1.0);
		if (season==2) tone=c*vec3(1.05,1.02,.84);
		if (season==3) tone=c*vec3(.81,1.07,1.04);
		if (blossom && season>=2 && season<=3) tone=vec3(.39,.57,.20)*(lum+.4);
		if (season==4) tone=vec3(.99,.68,.25)*(lum*1.35+.12);
		if (season==5) tone=vec3(.78,.44,.26)*(lum*1.25+.16);
		if (season>=6) {
			float cover=meadow ? smoothstep(.21,.68,lum) : smoothstep(.31,.65,lum);
			vec3 shade=vec3(.29,.40,.41)*(lum+.48);
			vec3 snow=mix(vec3(.67,.80,.84),vec3(.98,.97,.89),lum);
			tone=mix(shade,snow,cover*(season==7 ? .99 : .88));
		}
		c=mix(c,tone,(meadow && season<6) ? .65 : .91);
	}
	COLOR=vec4(c,src.a)*lighting;
}

