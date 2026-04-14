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

import gl "vendor:wasm/WebGL"
import "core:slice"
import "core:math/linalg"

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
	gl.CreateCurrentContextById(string(name), {})
	gl.SetCurrentContextById(string(name))

	//TODO: These can't be freed (probably ok since they last the whole program
	vs := #load("../res/vert_2d.glsl")
	fs := #load("../res/frag_texture.glsl")
	ctx.loaded_shader = shader_load_from_mem(vs, fs)
	gl.UseProgram(gl.Program(ctx.loaded_shader.hndl))

	/* font4_img, font4_img_ok := image.load_from_bytes(#load("../res/default_font.png"))
	assert(font4_img_ok == nil, fmt.tprintfln("%v", font4_img_ok))
	ctx.default_font = font_load(font4_img.pixels.buf[:], font4_img.width, font4_img.height, 32, 30) */

	white_rect: []u8 = make_slice([]u8, 1024) //NOTE: probably fine to jsut be heap allocated
	slice.fill(white_rect, 255)
	ctx.shape_texture_empty = sprite_load(white_rect, 16, 16)
	projection_set()
}

projection_set :: proc() {
	//Bottom left orientation
	projection := glm.mat4Ortho3d(
		0.0,
		f32(ctx.window_width),
		0.0,
		f32(ctx.window_height),
		-100.0,
		100.0,
	)

	//Top-Left orientation
	/* projection := glm.mat4Ortho3d(
		0.0,
		f32(ctx.window_width),
		f32(ctx.window_height),
		0.0,
		-100.0,
		100.0,
	) */
	/* gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0]) */
	shader_uniform_value_set("projection", .MATRIX_4, &projection[0, 0])
	ctx.view_matrix = linalg.identity(matrix[4, 4]f32)
	shader_uniform_value_set("view", .MATRIX_4, &ctx.view_matrix[0, 0])
}

background_clear :: proc(color: Colour) {
	r := f32(color.r) / 255.
	g := f32(color.g) / 255.
	b := f32(color.b) / 255.
	a := f32(color.a) / 255.
	gl.ClearColor(r, g, b, a)
	gl.Clear(u32(gl.COLOR_BUFFER_BIT) | u32(gl.DEPTH_BUFFER_BIT))
}
