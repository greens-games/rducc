#version 330 core

in vec2 TexCoord;
in vec3 pos;

out vec4 FragColor;

uniform vec4 colour;
uniform vec2 u_resolution;

float
fill_circle(in vec2 st) {
    float pct = step(distance(st,vec2(0.0)),1.0);
    return pct;
}

void main()
{
    vec2 st = pos.xy;
	float pct = fill_circle(st);
	vec4 final_colour = colour * pct;
	FragColor =  final_colour;
}
