#version 330 core 

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec4 i_colour; //inner colour

out vec2 TexCoord;
out vec4 colour;

uniform mat4 projection;
uniform mat4 view;

void main()
{
	vec4 proj_pos = projection * view * vec4(aPos, 1.0);
	TexCoord = aTexCoord;
	colour = i_colour;
	gl_Position = proj_pos;
}
