#version 330 core

in vec2 TexCoord;
in vec4 colour;

out vec4 FragColor;

uniform sampler2D ourTexture;
uniform float time;

void 
main()
{
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
	float adj = sin(time);
	FragColor = texture(ourTexture, TexCoord) * colour * adj;
}
