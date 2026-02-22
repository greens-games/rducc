#version 330 core 

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec4 i_colour; //inner colour
layout (location = 3) in vec4 b_colour; // border colour
//flag for if it's a circle or not this probably should be handled differently I don't think we want it to be a float
layout (location = 4) in float isCircle; 
//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
layout (location = 5) in vec3 dummy_pos;

out vec2 TexCoord;
out vec3 pos;
out vec4 colour;
out vec4 borderColour;
out float _isCircle;
//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
out vec3 _dummy_pos;

/* uniform mat4 transform; */
uniform mat4 projection;

void main()
{
	vec4 proj_pos = projection * vec4(aPos, 1.0);
	TexCoord = aTexCoord;
	pos = proj_pos.xyz;
	colour = i_colour;
	borderColour = b_colour;
	_isCircle = isCircle;
	//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
	_dummy_pos = dummy_pos;
	gl_Position = proj_pos;
}
