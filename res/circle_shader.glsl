#version 330 core

in vec2 TexCoord;

out vec4 FragColor;

uniform vec4 colour;
uniform vec2 u_resolution;

float
fill_circle(in vec2 st) {
    float pct = 0.0;
    pct = step(distance(st,vec2(0.5)),0.5);
    return pct;
}

void main()
{
    vec2 st = gl_FragCoord.xy/u_resolution;
	float pct = fill_circle(st);
	vec4 final_colour = colour * pct;
	FragColor =  final_colour;
}
