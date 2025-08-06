#version 330 core

in vec2 TexCoord;

out vec4 FragColor;

uniform vec4 colour;

void main()
{
	FragColor =  colour;
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
} 
