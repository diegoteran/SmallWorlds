shader_type canvas_item;

uniform float offset = 0.5;
uniform float speed = 1.0;
uniform float starting = -10.0;
uniform float spread = 0.05;
//uniform vec4 glow_color : hint_color = vec4(0.3);

void vertex() {
	VERTEX.x += cos(TIME * speed + offset) * (VERTEX.y + starting) * spread;
}