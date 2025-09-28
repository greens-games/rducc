#version 330 core

in vec2 TexCoord;
in vec3 pos;

out vec4 FragColor;

uniform vec4 colour;
uniform vec2 u_resolution;
uniform float size;

float
grid(vec2 st, float res){
    vec2 grid = fract(st*res);
    return 1.-(step(res,grid.x) * step(res,grid.y));
}

void main()
{
    vec2 st = pos.xy/u_resolution.xy;

	float s = size;
    float pct = grid(st * 320.0, 0.01);

    // Output to screen
	vec3 p = vec3(pct);
	vec3 final_colour = colour.rgb * p;
	FragColor =  vec4(final_colour, 1.0);
}
