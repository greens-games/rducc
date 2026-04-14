package plumage


import "core:mem"

/**
Table of Contents:
	UTILS ///////
	SHAPES
	TEXTURES
	FONTS
*/

/*
CONSIDER THIS THE renderer LAYER
	- Should be abstracted away from the platform layer (i.e try to avoid using glfw.gl_set_proc_address)
	- Intended to draw stuff (shapes, text, and textures mainly)
	- Don't want to add too many app specific things here
*/

import wgl "vendor:wasm/WebGL"

Vec2 :: [2]f32
Vec3 :: [3]f32

Color :: Colour
Colour :: [4]u8
//NOTE: These are ripped straight from Raylib could probably do something else if we wanted
LIGHTGRAY :: Colour{200, 200, 200, 255} // Light Gray
GRAY :: Colour{130, 130, 130, 255} // Gray
DARKGRAY :: Colour{80, 80, 80, 255} // Dark Gray
YELLOW :: Colour{253, 249, 0, 255} // Yellow
GOLD :: Colour{255, 203, 0, 255} // Gold
ORANGE :: Colour{255, 161, 0, 255} // Orange
PINK :: Colour{255, 109, 194, 255} // Pink
RED :: Colour{230, 41, 55, 255} // Red
MAROON :: Colour{190, 33, 55, 255} // Maroon
GREEN :: Colour{0, 228, 48, 255} // Green
LIME :: Colour{0, 158, 47, 255} // Lime
DARKGREEN :: Colour{0, 117, 44, 255} // Dark Green
SKYBLUE :: Colour{102, 191, 255, 255} // Sky Blue
BLUE :: Colour{0, 121, 241, 255} // Blue
DARKBLUE :: Colour{0, 82, 172, 255} // Dark Blue
PURPLE :: Colour{200, 122, 255, 255} // Purple
VIOLET :: Colour{135, 60, 190, 255} // Violet
DARKPURPLE :: Colour{112, 31, 126, 255} // Dark Purple
BEIGE :: Colour{211, 176, 131, 255} // Beige
BROWN :: Colour{127, 106, 79, 255} // Brown
DARKBROWN :: Colour{76, 63, 47, 255} // Dark Brown
WHITE :: Colour{255, 255, 255, 255} // White
BLACK :: Colour{0, 0, 0, 255} // Black
BLANK :: Colour{0, 0, 0, 0} // Blank (Transparent)
MAGENTA :: Colour{255, 0, 255, 255} // Magenta

CIRCLE_SEGMENTS :: 24

DEFAULT_BUFF_SIZE :: mem.Kilobyte * 64

vertices_index_box := [?]Vertex {
	{pos_coords = {1.0,   1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0, -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
}

Vertex :: struct {
	pos_coords:     [3]f32,
	texture_coords: [2]f32,
	colour:         [4]f32,
}

Rect :: struct {
	x:      f32,
	y:      f32,
	height: f32,
	width:  f32,
}

init :: proc(window_width, window_height: i32, name: cstring) {
	window_open(window_width, window_height, name)
	wgl.CreateCurrentContextById(string(name), {})
	wgl.SetCurrentContextById(string(name))

	//TODO: These can't be freed (probably ok since they last the whole program
	vs := #load("../res/vert_2d.glsl")
	fs := #load("../res/frag_texture.glsl")
	/* ctx.loaded_shader = shader_load_from_mem(vs, fs)
	wgl.UseProgram(wgl.Program(ctx.loaded_shader.hndl)) */
}

background_clear :: proc(color: Colour) {
	r := f32(color.r) / 255.
	g := f32(color.g) / 255.
	b := f32(color.b) / 255.
	a := f32(color.a) / 255.
	wgl.ClearColor(r, g, b, a)
	wgl.Clear(u32(wgl.COLOR_BUFFER_BIT) | u32(wgl.DEPTH_BUFFER_BIT))
}
