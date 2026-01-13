package rducc

import "core:slice/heap"
import "../debug"

import "core:hash"
import "core:image"
import "core:image/bmp"

import "core:mem/virtual"
import "core:mem"
import "core:math/linalg"
import "core:strings"
import "base:runtime"
import "core:slice"

import "core:c"
import stbi "vendor:stb/image"
/*
CONSIDER THIS THE renderer LAYER
	- Should be abstracted away from the platform layer (i.e try to avoid using glfw.gl_set_proc_address)
	- Intended to draw stuff (shapes, text, and textures mainly)
	- Don't want to add too many app specific things here
*/

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Colour :: distinct [4]int
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

DEFAULT_BUFF_SIZE :: mem.Kilobyte * 64

vertices_index_box := [?]Vertex {
	{pos_coords = {1.0,   1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0, -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
}

Render_Buffer :: enum u8 {
	RECT,
	CIRCLE,
	TEXTURE,
}


Vert_Info :: struct {
	pos:      [2]f32,
	scale:    [2]f32,
	rotation: f32,
	radius:   f32,
}

//NOTE: This is getting large maybe we can make it smaller somehow
//It's possible it's better still to do the maths on the cpu side and pass less as attributes?
Vertex :: struct {
	pos_coords:     [3]f32,
	texture_coords: [2]f32,
	colour:         [4]f32,
	border_colour:  [4]f32,
	is_circle:       f32,
	//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
	dummy_pos:     [3]f32,
}

init :: proc() {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address) //required for proc address stuff
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
	gl.DebugMessageCallback(debug_proc_t, {})
	gl.DebugMessageControl(
		gl.DEBUG_SOURCE_API,
		gl.DEBUG_TYPE_ERROR,
		gl.DEBUG_SEVERITY_HIGH,
		0,
		nil,
		gl.TRUE,
	)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	ctx.indices = make_slice([]u32, 6)
	ctx.indices[0] = 0
	ctx.indices[1] = 1
	ctx.indices[2] = 3
	ctx.indices[3] = 1
	ctx.indices[4] = 2
	ctx.indices[5] = 3

	gl.GenBuffers(1, &ctx.active_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.active_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, DEFAULT_BUFF_SIZE, nil, gl.DYNAMIC_DRAW)
	gl.GenVertexArrays(1, &ctx.active_vao)

	gl.BindVertexArray(ctx.active_vao)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)
	gl.EnableVertexAttribArray(4)

	//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
	gl.EnableVertexAttribArray(5)


	shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")

	font_image, font_image_ok := image.load_from_bytes(#load("../res/Font3.bmp"))
	assert(font_image_ok == nil)
	ctx.default_font = font_load(font_image.pixels.buf[:], font_image.height, font_image.width, 32, 32)

	width, height, channels: i32
	data := stbi.load("res/Font3.bmp", &width, &height, &channels, 4)

	//TODO: We seem to lose the texture data when we load like this over here I think
	ctx.default_font = font_load(data[:height * width], int(height), int(width), 32, 32)

	white_rect: []u8 = make_slice([]u8, 1024) //TODO: This might need to be an arena or something
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
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0])
}

debug_proc_t :: proc "c" (
	source: u32,
	type: u32,
	id: u32,
	severity: u32,
	length: i32,
	message: cstring,
	userParam: rawptr,
) {
	context = runtime.default_context()

	switch (type) {
	case gl.DEBUG_TYPE_ERROR:
		fmt.println("Type: Error")
		fmt.println("MESSAGE: ", message)
	}

}


background_clear :: proc(color: Colour) {
	r := f32(color.r) / 255.
	g := f32(color.g) / 255.
	b := f32(color.b) / 255.
	a := f32(color.a) / 255.
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

pixel :: proc(pos: [3]f32, colour: Colour) {
	vertices := [?]f32{-1.0, -1.0, 0.0}
	indices := [?]f32{0}
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	gl.DrawArrays(gl.POINTS, 0, len(vertices))
}

draw_box :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	texture := ctx.shape_texture_empty
	if (ctx.loaded_texture.hndl != 0 && texture.hndl != ctx.loaded_texture.hndl) {
		commit()
	}

	ctx.loaded_texture = texture

	push_vertices(pos, scale, colour)
}

draw_box_lines :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.active_render_group.vbo[Render_Buffer.RECT])

	v := vertices_index_box
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.

	for &vert in v {
		/* vert.pos = pos
		vert.scale = scale
		vert.rotation = rotation */
		vert.border_colour = colour_apply(colour)
		vert.colour = [4]f32{0,0,0,0}
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.active_render_group.box_vertices) * size_of(Vertex),
		size_of(v),
		&v,
	)

	ctx.active_render_group.box_vertices += len(vertices_index_box)
}

draw_circle :: proc(pos: [3]f32, radius: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	texture := ctx.shape_texture_empty
	if (ctx.loaded_texture.hndl <= 0 && texture.hndl != ctx.loaded_texture.hndl) {
		commit()
	}

	ctx.loaded_texture = texture

	push_vertices(pos, radius, colour, is_circle = true)
}

sprite_atlas_load :: proc(data: []u8, height, width:int, sprite_size: i32) -> Ducc_Texture_Atlas {
	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture_hndl)

	texture_atlas: Ducc_Texture_Atlas
	texture_atlas.data        = data
	texture_atlas.height      = i32(height)
	texture_atlas.width       = i32(width)
	texture_atlas.hndl        = texture_hndl
	texture_atlas.sprite_size = sprite_size
	texture_atlas.rows        = (i32(height)/sprite_size) 
	texture_atlas.cols        = (i32(width)/sprite_size) 
	return texture_atlas
}

//Takes in position data, texture data to be drawn, and index into the atlas from top down
//i.e 0,0 will be top left. atlas.rows - 1, atlas.cols - 1 will be bottom right
draw_sprite_atlas :: proc(atlas: Ducc_Texture_Atlas, pos: [3]f32, scale: [2]f32, idx: [2]i32, rotation: f32 = 0.0, colour := RED) {
	if (ctx.loaded_texture.hndl != 0 && atlas.hndl != ctx.loaded_texture.hndl) {
		commit()
	}
	ctx.loaded_texture = Ducc_Texture {
		data   = atlas.data,
		height = i32(atlas.height),
		width  = i32(atlas.width),
		hndl   = atlas.hndl,
	}

	offset := 1.0/f32(atlas.rows)

	//Top down
	//TODO: Document what these values are meant to represent
	y_offset := f32(atlas.rows - idx.y) * offset
	y_offset_minus_one := f32(atlas.rows - idx.y - 1) * offset
	x_offset := f32(idx.x) * offset
	x_offset_plus_one := f32(idx.x + 1) * offset
	vertices := [?]Vertex {
		{
			pos_coords = {
				pos.x + scale.x,
				pos.y + scale.y,
				0.0
			},
			texture_coords = {
				x_offset_plus_one,
				y_offset
			}
		},
		{
			pos_coords = {
				pos.x + scale.x,
				pos.y,
				0.0
			},
			texture_coords = {
				x_offset_plus_one,
				y_offset_minus_one
			}
		},
		{
			pos_coords = {
				pos.x,
				pos.y + scale.y,
				0.0
			},
			texture_coords = {
				x_offset,
				y_offset
			}
		},
		{
			pos_coords = {
				pos.x + scale.x,
				pos.y,
				0.0
			},
			texture_coords = {
				x_offset_plus_one,
				y_offset_minus_one
			}
		},
		{
			pos_coords = {
				pos.x,
				pos.y,
				0.0
			},
			texture_coords = {
				x_offset,
				y_offset_minus_one
			}
		},
		{
			pos_coords = {
				pos.x,
				pos.y + scale.y,
				0.0
			},
			texture_coords = {
				x_offset,
				y_offset
			}
		},
	}

	for &vert, i in vertices {
		vert.colour   = colour_apply(colour)
		vert.is_circle = f32(int(false))
		vert.dummy_pos = vertices_index_box[i].pos_coords
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.batch_vertices_count) * size_of(Vertex),
		size_of(vertices),
		&vertices,
	)
	ctx.batch_vertices_count += len(vertices)
}

//Read in some file name
//Return back data about the texture
sprite_load :: proc(data: []u8, height, width: int)  -> Ducc_Texture {
	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)

	texture: Ducc_Texture
	//TODO: We probably want our system to not have to store all our texture data in memory all the time
	texture.data   = data
	texture.height = i32(height)
	texture.width  = i32(width)
	texture.hndl   = texture_hndl
	return texture
}

//Takes in position data, and texture data to be drawn
draw_sprite :: proc(texture: Ducc_Texture, pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := WHITE) {
	if (ctx.loaded_texture.hndl != 0 && texture.hndl != ctx.loaded_texture.hndl) {
		commit()
	}

	ctx.loaded_texture = texture
	push_vertices(pos, scale, colour)
}

push_vertices :: proc(pos: [3]f32, scale: [2]f32, colour: Colour, is_circle := false) {
	vertices := [?]Vertex {
		{pos_coords = {pos.x + scale.x, pos.y + scale.y, 0.0}, texture_coords = {1.0, 0.0}},
		{pos_coords = {pos.x + scale.x, pos.y, 0.0},           texture_coords = {1.0, 1.0}},
		{pos_coords = {pos.x, pos.y + scale.y, 0.0},           texture_coords = {0.0, 0.0}},
		{pos_coords = {pos.x + scale.x, pos.y, 0.0},           texture_coords = {1.0, 1.0}},
		{pos_coords = {pos.x, pos.y, 0.0},                     texture_coords = {0.0, 1.0}},
		{pos_coords = {pos.x, pos.y + scale.y, 0.0},           texture_coords = {0.0, 0.0}},
	}
	for &vert, i in vertices {
		vert.colour   = colour_apply(colour)
		vert.is_circle = f32(int(is_circle))
		vert.dummy_pos = vertices_index_box[i].pos_coords
	}

	/* for vert in vertices {
		ctx.batch_vertices[ctx.batch_vertices_count] = vert
		ctx.batch_vertices_count += 1
	} */

	//TODO: Instead of using subData here we can store all vertex info on the CPU in Context then pass that to the gpu in @commit()
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.batch_vertices_count) * size_of(Vertex),
		size_of(vertices),
		&vertices,
	)
	ctx.batch_vertices_count += len(vertices)
}

//push_vertex :: proc(pos_coord, texture_coord, colour, is_circle := false)

font_load :: proc(font_data: []u8, height, width: int, offset: i32, sprite_size: i32) -> Ducc_Font {
	return font_bmp_load(font_data, height, width, offset, sprite_size)
}

font_bmp_load :: proc(font_data: []u8, height, width: int, offset: i32, sprite_size: i32) -> Ducc_Font {
	texture := sprite_atlas_load(font_data, height, width, sprite_size)
	
	font: Ducc_Font
	font.hndl = texture.hndl
	font.data = texture.data
	font.height = texture.height
	font.width = texture.width
	font.rows = texture.height/sprite_size
	font.cols = texture.width/sprite_size
	font.sprite_size = sprite_size
	font.offset = offset

	return font
}

/**
take in a loaded font, line of text, position, font_size, and colour
currently maps the font to a texture atlas and calls the renderer's texture atlas draw proc
*/
draw_text :: proc(font: Ducc_Font, text: string, pos: [2]f32, font_size: f32, colour: Colour = WHITE) {
	texture: Ducc_Texture_Atlas = {
		hndl = font.hndl,
		data = font.data,
		height = font.height,
		width = font.width,
		rows = font.rows,
		cols = font.cols,
		sprite_size = font.sprite_size
	}
	upper_text := strings.to_upper(text, context.temp_allocator)
	for c, i in upper_text {
		offset_c := i32(c) - font.offset //offset our character so it can be indexed into the array
		idx_y    := offset_c / 8 //find the row in our atlas from top to bottom
		adj_cols := ((font.cols) * i32(idx_y)) //find the starting point for the row in our imaginary flat array
		normalized_offset := (i32(offset_c) - adj_cols) //normalize our char index to be 0 to (cols- 1) so we can index into the row
		draw_sprite_atlas(texture, {pos.x + f32((i32(i) * i32(font_size))), pos.y, 0.0}, {font_size, font_size}, {i32(normalized_offset), i32(idx_y)}, colour = colour)
	}
}

@(private)
colour_apply :: proc(colour: Colour) -> [4]f32 {
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.
	return {r, g, b, a}
}

vertex_apply :: proc(pos: [3]f32, scale: [2]f32, rotation: f32) -> [3]f32 {
	adjusted_scale := [2]f32{scale.x/2., scale.y/2.}
	i := glm.identity(glm.mat4)
	t := glm.mat4Translate({pos.x + adjusted_scale.x,pos.y + adjusted_scale.y, 0.})
	s := glm.mat4Scale({adjusted_scale.x,adjusted_scale.y,1.0})
	rot := glm.mat4Rotate({0.0,0.0,1.0}, glm.radians(rotation))
	i *= t
	/* i *= rot */
	i *= s
	temp_pos := [4]f32{pos.x, pos.y, pos.z, 1.0}
	ret := i * temp_pos
	return ret.xyz
}


commit :: proc() {
	gl.BindTexture(gl.TEXTURE_2D, ctx.loaded_texture.hndl)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, ctx.loaded_texture.height, ctx.loaded_texture.width, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(ctx.loaded_texture.data))
	vertex_attrib_apply()
	gl.GenerateMipmap(gl.TEXTURE_2D)
	if window_is_key_pressed(.KEY_A) {
		for i in 0..<ctx.batch_vertices_count {
			fmt.println(ctx.batch_vertices[i])
	}
		fmt.println()
	}
	/* blah := ctx.batch_vertices[:ctx.batch_vertices_count]
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.batch_vertices_count) * size_of(Vertex),
		size_of(ctx.batch_vertices[:ctx.batch_vertices_count]),
		&blah,
	) */
	gl.DrawArrays(gl.TRIANGLES, 0, ctx.batch_vertices_count)
	ctx.batch_vertices_count = 0
}

vertex_attrib_apply :: proc() {
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), (0 * size_of(f32)))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), (3 * size_of(f32)))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), (5 * size_of(f32)))
	gl.VertexAttribPointer(3, 4, gl.FLOAT, false, size_of(Vertex), (9 * size_of(f32)))
	gl.VertexAttribPointer(4, 1, gl.FLOAT, false, size_of(Vertex), (13 * size_of(f32)))
	//TODO: remove dummy_pos stuff when after fixing fill_circle logic for actual position
	gl.VertexAttribPointer(5, 3, gl.FLOAT, false, size_of(Vertex), (14 * size_of(f32)))
}
