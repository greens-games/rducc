#version 330 core

in vec2 TexCoord;
in vec3 pos;
in vec4 colour;

out vec4 FragColor;

void
main() {
	FragColor =  colour;
}
/* #version 330 core

in vec2 TexCoord;
in vec4 colour;

out vec4 FragColor;


void main()
{
	FragColor =  colour;
} */
