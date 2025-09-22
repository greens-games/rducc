#version 330 core

in vec2 TexCoord;

out vec4 FragColor;

uniform vec4 colour;
uniform sampler2D ourTexture;

void main()
{
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
	FragColor = texture(ourTexture, TexCoord) * colour;
} 
