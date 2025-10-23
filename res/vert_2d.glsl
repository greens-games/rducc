#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec3 localPos;
layout (location = 3) in vec2 localScale;
layout (location = 4) in float rotation;
layout (location = 5) in vec4 i_colour;

out vec2 TexCoord;
out vec3 pos;
out vec4 colour;

/* uniform mat4 transform; */
uniform mat4 projection;

void main()
{
	//make transformation matrix
	mat4 ident = mat4(1.0);
	vec3 adjusted_scale = vec3(localScale.x / 2.0, localScale.y / 2.0, 1.0);
	vec3 adjustLocalPos = vec3(localPos.x + adjusted_scale.x, localPos.y + adjusted_scale.y, 0.0);
	ident[3].xyz = adjustLocalPos.xyz;
	mat4 s = mat4(1.0);
	s[0][0] = adjusted_scale[0];
	s[1][1] = adjusted_scale[1];
	s[2][2] = adjusted_scale[2];
	s[3][3] = 1;
	ident = ident * s;
	gl_Position = projection * ident * vec4(aPos, 1.0);
	TexCoord = aTexCoord;
	pos = aPos;
	colour = i_colour;
}
