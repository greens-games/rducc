#version 330 core

in vec2 TexCoord;
in vec4 colour;

out vec4 FragColor;


void main()
{
	FragColor =  colour;
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
}
