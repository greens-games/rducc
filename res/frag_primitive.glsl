#version 330 core

in vec2 TexCoord;
in vec3 pos;
in vec4 colour;
in vec4 borderColour;

out vec4 FragColor;

//NOTE: There's definitely a better way to do outlining but for now this works
void
main() {
	float thickness = 0.80;

    vec4 blank = vec4(0.0);
    vec2 uv = pos.xy;

    float left = step(uv.x, -thickness);
    float right = step(thickness, uv.x);
    float bot = step(uv.y, -thickness);
    float top = step(thickness, uv.y);

    vec4 finalCol = (left == 0.0 && right == 0.0 && top == 0.0 && bot == 0.0) || borderColour.a == 0.0 ? colour : borderColour;

	FragColor = finalCol;
	/* FragColor = colour; */
}
/* #version 330 core

in vec2 TexCoord;
in vec4 colour;

out vec4 FragColor;


void main()
{
	FragColor =  colour;
} */
