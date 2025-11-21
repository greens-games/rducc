
#version 330 core

in vec2 TexCoord;

out vec4 FragColor;

uniform vec4 colour;
uniform sampler2D ourTexture;

float
outline_rect(in vec2 st, in vec2 pos, in float scale) {
	float pct = 0.0;
	float offset = 0.004;

	float o_left = step(st.x,pos.x) * step(pos.x-offset, st.x) * 	(step(pos.y,st.y) * step(st.y,1.0-scale));
	pct += o_left;

	float o_right = step(st.x,1.0-scale ) * step(1.0-offset-scale, st.x) * (step(pos.y,st.y) * step(st.y,1.0-scale));
	pct += o_right;

	float o_bot = step(st.y,pos.y) * step(pos.y-offset, st.y) * (step(pos.x,st.x) * step(st.x,1.0-scale));
	pct += o_bot;

	float o_top = step(st.y,1.0-scale) * step(1.0-offset-scale, st.y) * (step(pos.x,st.x) * step(st.x,1.0-scale));
	pct += o_top;

	return pct;
}

float
fill_circle(in vec2 st) {
    float pct = 0.0;
    pct = step(distance(st,vec2(0.5)),0.5);
    return pct;
}

void
main() {
}
