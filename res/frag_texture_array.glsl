#version 330 core

in vec3 TexCoord;
in vec4 colour;

out vec4 FragColor;

uniform sampler2DArray ourTexture;

void main()
{
	//FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2); mixing textures
	//vec3 newCoord = vec3(TexCoord, 0.0);
	FragColor = texture(ourTexture, TexCoord) * colour;
} 
