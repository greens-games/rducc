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
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:math/linalg"
import "core:math"
import "core:fmt"
import "core:image"
import "core:image/png"

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
	gl.CreateCurrentContextById(string(name), gl.DEFAULT_CONTEXT_ATTRIBUTES)
	gl.SetCurrentContextById(string(name))
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	gl.Enable(gl.BLEND)

	ctx.active_vbo = u32(gl.CreateBuffer())
	gl.BindBuffer(gl.ARRAY_BUFFER, gl.Buffer(ctx.active_vbo))
	gl.BufferData(gl.ARRAY_BUFFER, mem.Megabyte, nil, gl.STREAM_DRAW)

	//TODO: These can't be freed (probably ok since they last the whole program
	vs := #load("res/default_vert.glsl")
	fs := #load("res/default_frag.glsl")
	ctx.loaded_shader = shader_load_from_mem(vs, fs)
	gl.UseProgram(gl.Program(ctx.loaded_shader.hndl))

	font4_img, font4_img_ok := image.load_from_bytes(#load("../res/default_font.png"))
	assert(font4_img_ok == nil, fmt.tprintfln("%v", font4_img_ok))
	ctx.default_font = font_load(font4_img.pixels.buf[:], font4_img.width, font4_img.height, 32, 30)

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

box_push :: proc{
	box_base_push, box_rotate_push 
}

/*
Basic box draw that does not rotate
*/
box_base_push :: proc(pos: [2]f32, scale: [2]f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	top_left: Vec3 = {pos.x, pos.y + scale.y, 0}
	bot_left: Vec3 = {pos.x, pos.y, 0}
	top_right: Vec3 = {pos.x + scale.x, pos.y + scale.y, 0}
	bot_right: Vec3 = {pos.x + scale.x, pos.y, 0}

	vertex_push(top_right, {1.0, 0.0}, colour)
	vertex_push(bot_right, {1.0, 1.0}, colour)
	vertex_push(top_left,  {0.0, 0.0}, colour)
	vertex_push(bot_right, {1.0, 1.0}, colour)
	vertex_push(bot_left,  {0.0, 1.0}, colour)
	vertex_push(top_left,  {0.0, 0.0}, colour)
}

/*
supply origin and rotation to tell box what to rotate around
rotation is in degress i.e 45 degree angle
{0, 0} origin is bottom left
scale/2 origin is centre
*/
box_rotate_push :: proc(pos, origin, scale: [2]f32, rotation:f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	rotation := math.to_radians_f32(rotation)
	bot_left, bot_right, top_left, top_right := rect_rotate(pos, origin, scale, rotation)

	vertex_push(top_right, {1.0, 0.0}, colour, rotation)
	vertex_push(bot_right, {1.0, 1.0}, colour, rotation)
	vertex_push(top_left,  {0.0, 0.0}, colour, rotation)
	vertex_push(bot_right, {1.0, 1.0}, colour, rotation)
	vertex_push(bot_left,  {0.0, 1.0}, colour, rotation)
	vertex_push(top_left,  {0.0, 0.0}, colour, rotation)
}

font_load :: proc(font_data: []u8, width, height: int, offset: i32, sprite_size: i32) -> Ducc_Font {
	return font_bmp_load(font_data, width, height, offset, sprite_size)
}

//TODO: This requires the bitmap to be a square rows == cols
font_bmp_load :: proc(font_data: []u8, width, height: int, offset: i32, sprite_size: i32) -> Ducc_Font {
	texture := sprite_atlas_load(font_data, width, height, sprite_size)
	
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
//TODO: This requires the bitmap to be a square rows == cols
text_push :: proc(text: string, pos: [2]f32, font_size: f32, font: Ducc_Font = ctx.default_font, colour: Colour = WHITE) {
	_pos := pos
	texture: Ducc_Texture_Atlas = {
		hndl = font.hndl,
		data = font.data,
		height = font.height,
		width = font.width,
		rows = font.rows,
		cols = font.cols,
		sprite_size = font.sprite_size,
		mode        = u32(gl.TRIANGLES)
	}
	i := 0
	for c in text {
		switch c {
		case '\n':
			_pos.y -= font_size //TODO: If we swap to top left origin this changes to +
			i = 0
			continue
		}
		rune_push(c, {_pos.x + f32((i32(i) * i32(font_size))), _pos.y}, font_size, font, colour = colour)
		i += 1
	}
}

rune_push :: proc(c: rune, pos: [2]f32, font_size: f32, font: Ducc_Font = ctx.default_font, colour: Colour = WHITE) {
	_pos := pos
	texture: Ducc_Texture_Atlas = {
		hndl = font.hndl,
		data = font.data,
		height = font.height,
		width = font.width,
		rows = font.rows,
		cols = font.cols,
		sprite_size = font.sprite_size,
		mode        = u32(gl.TRIANGLES)
	}
	switch c {
	case '\n':
		_pos.y -= font_size
	}
	offset_c := i32(c) - font.offset //offset our character so it can be indexed into the array
	index_y    := offset_c / font.rows //find the row in our atlas from top to bottom
	adj_cols := ((font.cols) * i32(index_y)) //find the starting point for the row in our imaginary flat array
	normalized_offset := (i32(offset_c) - adj_cols) //normalize our char index to be 0 to (cols- 1) so we can index into the row
	sprite_atlas_index_push(texture, {_pos.x, _pos.y}, {font_size, font_size}, {i32(normalized_offset), i32(index_y)}, colour = colour)
}

//////////////////////
////TC: TEXTURES
//////////////////////
sprite_atlas_load :: proc(data: []u8, width, height:int, sprite_size: i32) -> Ducc_Texture_Atlas {
	texture_hndl: u32
	texture_hndl = u32(gl.CreateTexture())
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, gl.Texture(texture_hndl))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(gl.LINEAR_MIPMAP_LINEAR))

	texture_atlas: Ducc_Texture_Atlas
	texture_atlas.data        = data
	texture_atlas.height      = i32(height)
	texture_atlas.width       = i32(width)
	texture_atlas.hndl        = texture_hndl
	texture_atlas.sprite_size = sprite_size
	texture_atlas.rows        = (i32(height)/sprite_size) 
	texture_atlas.cols        = (i32(width)/sprite_size) 
	texture_atlas.mode        = u32(gl.TRIANGLES)
	return texture_atlas
}

//Takes in position data, texture data to be drawn, and index into the atlas from top down
//i.e 0,0 will be top left. atlas.rows - 1, atlas.cols - 1 will be bottom right
//TODO: For non stb loaded images this is upside down
//TODO: Instead of using indices for getting the texture should use sizes
sprite_atlas_index_push :: proc(atlas: Ducc_Texture_Atlas, pos: [2]f32, scale: [2]f32, index: [2]i32, rotation: f32 = 0.0, colour: Colour = WHITE) {
	if should_commit(atlas.hndl, atlas.mode) {
		commit()
	}
	ctx.loaded_texture = Ducc_Texture {
		data   = atlas.data,
		height = i32(atlas.height),
		width  = i32(atlas.width),
		hndl   = atlas.hndl,
		mode   = atlas.mode
	}

	row_offset := 1.0/f32(atlas.rows)
	col_offset := 1.0/f32(atlas.cols)

	//Top down
	//TODO: Document what these values are meant to represent
	y_offset := f32(index.y) * row_offset
	y_offset_minus_one := f32(index.y + 1) * row_offset
	x_offset := f32(index.x) * col_offset
	x_offset_plus_one := f32(index.x + 1) * col_offset
	vertex_push({pos.x + scale.x, pos.y + scale.y, 0.0},{x_offset_plus_one, y_offset}, colour)
	vertex_push({pos.x + scale.x, pos.y, 0.0},{x_offset_plus_one, y_offset_minus_one}, colour)
	vertex_push({pos.x, pos.y + scale.y, 0.0},{x_offset, y_offset}, colour)
	vertex_push({pos.x + scale.x, pos.y, 0.0},{x_offset_plus_one, y_offset_minus_one}, colour)
	vertex_push({pos.x, pos.y, 0.0},{x_offset, y_offset_minus_one}, colour)
	vertex_push({pos.x, pos.y + scale.y, 0.0},{x_offset, y_offset}, colour)

}

sprite_atlas_push :: proc(atlas: Ducc_Texture_Atlas, pos: [2]f32, scale: [2]f32, src: Rect, rotation: f32 = 0.0, colour: Colour = WHITE) {
	assert(src.x <= f32(atlas.width))
	assert(src.y <= f32(atlas.height))
	if should_commit(atlas.hndl, atlas.mode) {
		commit()
	}
	ctx.loaded_texture = Ducc_Texture {
		data   = atlas.data,
		height = i32(atlas.height),
		width  = i32(atlas.width),
		hndl   = atlas.hndl,
		mode   = atlas.mode
	}

	start_x := src.x / f32(atlas.width)
	start_y := src.y / f32(atlas.height)

	end_x := (src.width  + src.x) / f32(atlas.width)
	end_y := (src.height + src.y) / f32(atlas.height)
	
	vertex_push({pos.x + scale.x, pos.y + scale.y, 0.0},{end_x, start_y},     colour)
	vertex_push({pos.x + scale.x, pos.y, 0.0},          {end_x, end_y},   colour)
	vertex_push({pos.x, pos.y + scale.y, 0.0},          {start_x, start_y},   colour)
	vertex_push({pos.x + scale.x, pos.y, 0.0},          {end_x, end_y},   colour)
	vertex_push({pos.x, pos.y, 0.0},                    {start_x, end_y}, colour)
	vertex_push({pos.x, pos.y + scale.y, 0.0},          {start_x, start_y},   colour)

}

sprite_atlas_rotate_push :: proc(atlas: Ducc_Texture_Atlas, pos, origin, scale: [2]f32, src: Rect, rotation: f32 = 0.0, colour: Colour = WHITE) {

	assert(src.x <= f32(atlas.width))
	assert(src.y <= f32(atlas.height))
	if should_commit(atlas.hndl, atlas.mode) {
		commit()
	}
	ctx.loaded_texture = Ducc_Texture {
		data   = atlas.data,
		height = i32(atlas.height),
		width  = i32(atlas.width),
		hndl   = atlas.hndl,
		mode   = atlas.mode
	}

	start_x := src.x / f32(atlas.width)
	start_y := src.y / f32(atlas.height)

	end_x := (src.width  + src.x) / f32(atlas.width)
	end_y := (src.height + src.y) / f32(atlas.height)
	rotation := math.to_radians_f32(rotation)
	
	bot_left, bot_right, top_left, top_right := rect_rotate(pos, origin, scale, rotation)

	vertex_push(top_right,{end_x, start_y},     colour)
	vertex_push(bot_right,          {end_x, end_y},   colour)
	vertex_push(top_left,          {start_x, start_y},   colour)
	vertex_push(bot_right,          {end_x, end_y},   colour)
	vertex_push(bot_left,                    {start_x, end_y}, colour)
	vertex_push(top_left,          {start_x, start_y},   colour)
}

sprite_load :: proc(data: []u8, width, height: int)  -> Ducc_Texture {
	texture_hndl: u32
	texture_hndl = u32(gl.CreateTexture())
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, gl.Texture(texture_hndl))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(gl.LINEAR_MIPMAP_LINEAR))

	texture: Ducc_Texture
	//TODO: We probably want our system to not have to store all our texture data in memory all the time
	texture.data   = data
	texture.height = i32(height)
	texture.width  = i32(width)
	texture.hndl   = texture_hndl
	texture.mode   = u32(gl.TRIANGLES)
	return texture
}

vertex_push :: proc(pos_coords: [3]f32, uv_coords: [2]f32, colour: Colour, rotation: f32 = 0.0) {
	vertex: Vertex
	vertex.pos_coords = pos_coords
	vertex.texture_coords = uv_coords
	vertex.colour = colour_apply(colour)

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		uintptr(int(ctx.batch_vertices_count) * size_of(Vertex)),
		size_of(Vertex),
		&vertex,
	)

	//NOTE: this appears to be slower at based solely on monitoring fps (surface level)
	/* start := ctx.batch_vertices_count * ctx.loaded_shader.vertex_size
	(^Vertex)(&ctx.batch_vertices[start])^ = vertex */

	ctx.batch_vertices_count += 1
}

@(private)
rect_rotate :: proc(pos, origin, scale: [2]f32, rotation: f32) -> (
	bot_left: Vec3,
	bot_right: Vec3,
	top_left: Vec3,
	top_right: Vec3,
) {
	//We are assuming origin around centre (Could add an optional field later)
	_origin := pos + origin //Centre of shape

	dx: f32 = -origin.x
	dy: f32 = -origin.y

	sin_rot := math.sin(rotation)
	cos_rot := math.cos(rotation)

	bot_left = Vec3{
		_origin.x + dx * cos_rot - dy * sin_rot,
		_origin.y + dx * sin_rot + dy * cos_rot,
		0.0,
	}

	bot_right = Vec3{
		_origin.x + (dx + scale.x) * cos_rot - dy * sin_rot,
		_origin.y + (dx + scale.x) * sin_rot + dy * cos_rot,
		0.0,
	}

	top_left = Vec3{
		_origin.x + dx * cos_rot - (dy + scale.y) * sin_rot,
		_origin.y + dx * sin_rot + (dy + scale.y) * cos_rot,
		0.0,
	}

	top_right = Vec3{
		_origin.x + (dx + scale.x) * cos_rot - (dy + scale.y) * sin_rot,
		_origin.y + (dx + scale.x) * sin_rot + (dy + scale.y) * cos_rot,
		0.0,
	}
	return
}

@(private)
should_commit :: proc(hndl: u32, mode: u32) -> bool {
	if ctx.batch_vertices_count * ctx.loaded_shader.vertex_size >= DEFAULT_BUFF_SIZE { return true }
	if ctx.loaded_texture.hndl != 0 && hndl != ctx.loaded_texture.hndl { return true }
	if ctx.loaded_texture.mode != 0 && ctx.loaded_texture.mode != mode { return true }
	return false
}

@(private)
colour_apply :: proc(colour: Colour) -> [4]f32 {
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.
	return {r, g, b, a}
}

commit :: proc() {
	if ctx.batch_vertices_count == 0 { return }
	if ctx.camera != nil {
		shader_uniform_value_set("view", .MATRIX_4, &ctx.view_matrix[0, 0])
	}

	gl.BindVertexArray(gl.VertexArrayObject(ctx.loaded_shader.vao))

	//NOTE: this appears to be slower at based solely on monitoring fps (surface level)
	/* vb_data := gl.MapBuffer(gl.ARRAY_BUFFER, gl.WRITE_ONLY)
	{
		gpu_map := slice.from_ptr((^u8)(vb_data), DEFAULT_BUFF_SIZE)
		copy(
			gpu_map,
			ctx.batch_vertices[:ctx.batch_vertices_count * size_of(Vertex)],
		)
	}
	gl.UnmapBuffer(gl.ARRAY_BUFFER) */
/*
TexImage2D    :: proc(target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, format, type: Enum, size: int, data: rawptr) ---

impl_TexImage2D:             proc "c" (target: u32, level: i32, internalformat: i32, width: i32, height: i32, border: i32, format: u32, type: u32, pixels: rawptr)
*/

	gl.BindTexture(gl.TEXTURE_2D, gl.Texture(ctx.loaded_texture.hndl))
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, ctx.loaded_texture.width, ctx.loaded_texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, int(ctx.loaded_texture.width * ctx.loaded_texture.height * 4), raw_data(ctx.loaded_texture.data))
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.DrawArrays(gl.Enum(ctx.loaded_texture.mode), 0, int(ctx.batch_vertices_count))
	ctx.batch_vertices_count = 0
}
