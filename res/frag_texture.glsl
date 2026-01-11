#version 330 core

in vec2 TexCoord;
in vec3 pos;
in vec4 colour;
in float _isCircle;
//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
in vec3 _dummy_pos;

out vec4 FragColor;

uniform sampler2D ourTexture;

float
fill_circle(in vec2 st) {
    float pct = step(distance(st,vec2(0.0)),1.0);
    return pct;
}

void 
main()
{
    vec2 st = _dummy_pos.xy;
	float pct = _isCircle == 1.0 ? fill_circle(st) : 1.0;
	vec4 final_colour = colour * pct;
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
	FragColor = texture(ourTexture, TexCoord) * final_colour;
}
