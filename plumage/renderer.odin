package plumage

import "core:math"
import "core:math/linalg"
import "core:image"
import "core:image/bmp"
import "core:image/png"

import "core:mem"
import "core:strings"
import "base:runtime"
import "core:slice"
import stbi "vendor:stb/image"

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

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

_ :: bmp
_ :: png

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
}

init :: proc(window_width, window_height: i32, name: cstring) {
	window_open(window_width, window_height, name)
	gl.load_up_to(4, 6, glfw.gl_set_proc_address) //required for proc address stuff
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.DebugMessageCallback(debug_proc_t, {})
	gl.DebugMessageControl(
		gl.DEBUG_SOURCE_API,
		gl.DEBUG_TYPE_ERROR,
		gl.DEBUG_SEVERITY_HIGH,
		0,
		nil,
		gl.TRUE,
	)

	//TODO: These can't be freed (probably ok since they last the whole program
	vs := #load("res/vert_2d.glsl")
	fs := #load("res/frag_texture.glsl")
	shader_load_from_mem(vs, fs)


	when 1 == 0 {
		gl.GenBuffers(1, &ctx.active_vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, ctx.active_vbo)
		gl.BufferData(gl.ARRAY_BUFFER, mem.Megabyte, nil, gl.DYNAMIC_DRAW)

		gl.GenVertexArrays(1, &ctx.active_vao)
		gl.BindVertexArray(ctx.active_vao)
		gl.EnableVertexAttribArray(0)
		gl.EnableVertexAttribArray(1)
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), (0 * size_of(f32)))
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), (3 * size_of(f32)))
		gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), (5 * size_of(f32)))
	}

	font4_img, font4_img_ok := image.load_from_bytes(#load("res/default_font.png"))
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
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0])
	ctx.view_matrix = linalg.identity(matrix[4, 4]f32)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["view"].location, 1, false, &ctx.view_matrix[0, 0])
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

//////////////////////
/////TC: SHAPES //////
//////////////////////
push_pixel :: proc(pos: [2]f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	texture.mode = gl.POINTS
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	push_vertex({pos.x, pos.y, 0.0}, {1.0, 0.0}, colour)
}

//TODO: Potentially temporary group as we want push_line_box to be go to I believe
//Currently it makes the grid look cool but not right for most scenarios

push_line_lines :: proc(start: [2]f32, end: [2]f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	texture.mode = gl.LINES
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	push_vertex({start.x, start.y, 0.0}, {1.0, 0.0}, colour)
	push_vertex({end.x, end.y, 0.0},     {1.0, 1.0}, colour)
}

push_line :: proc(start: [2]f32, end: [2]f32, colour: Colour, thickness: f32 = 1) {
	texture := ctx.shape_texture_empty
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	length2 := end - start
	l := linalg.length(length2)
	//TODO: To do proper rotation we would want to fix/change rotation of a box to have custom origin
	rot := math.atan2(end.y - start.y, end.x - start.x)
	/* linalg.normalize */
	push_box({start.x, start.y}, {0, 0}, {l, thickness}, rot, colour)
}

//NOTE: Trying out procedure groups here not sure if it's needed or too much
//Trying to confine the logic here into 1 made the signature to long for the basic behaviour for my liking
push_box :: proc{
	push_box_base, push_box_rotate
}

/*
Basic box draw that does not rotate
*/
push_box_base :: proc(pos: [2]f32, scale: [2]f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	top_left: Vec3 = {pos.x, pos.y + scale.y, 0}
	bot_left: Vec3 = {pos.x, pos.y, 0}
	top_right: Vec3 = {pos.x + scale.x, pos.y + scale.y, 0}
	bot_right: Vec3 = {pos.x + scale.x, pos.y, 0}

	push_vertex(top_right, {1.0, 0.0}, colour)
	push_vertex(bot_right, {1.0, 1.0}, colour)
	push_vertex(top_left,  {0.0, 0.0}, colour)
	push_vertex(bot_right, {1.0, 1.0}, colour)
	push_vertex(bot_left,  {0.0, 1.0}, colour)
	push_vertex(top_left,  {0.0, 0.0}, colour)
}

/*
supply origin and rotation to tell box what to rotate around
rotation is in degress i.e 45 degree angle
{0, 0} origin is bottom left
scale/2 origin is centre
*/
push_box_rotate :: proc(pos, origin, scale: [2]f32, rotation:f32, colour: Colour) {
	texture := ctx.shape_texture_empty
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	//We are assuming origin around centre (Could add an optional field later)
	_origin := pos + origin //Centre of shape

	dx: f32 = -origin.x
	dy: f32 = -origin.y

	sin_rot := math.sin(rotation)
	cos_rot := math.cos(rotation)

	bot_left := Vec3{
		_origin.x + dx * cos_rot - dy * sin_rot,
		_origin.y + dx * sin_rot + dy * cos_rot,
		0.0,
	}

	bot_right := Vec3{
		_origin.x + (dx + scale.x) * cos_rot - dy * sin_rot,
		_origin.y + (dx + scale.x) * sin_rot + dy * cos_rot,
		0.0,
	}

	top_left := Vec3{
		_origin.x + dx * cos_rot - (dy + scale.y) * sin_rot,
		_origin.y + dx * sin_rot + (dy + scale.y) * cos_rot,
		0.0,
	}

	top_right := Vec3{
		_origin.x + (dx + scale.x) * cos_rot - (dy + scale.y) * sin_rot,
		_origin.y + (dx + scale.x) * sin_rot + (dy + scale.y) * cos_rot,
		0.0,
	}

	push_vertex(top_right, {1.0, 0.0}, colour, rotation)
	push_vertex(bot_right, {1.0, 1.0}, colour, rotation)
	push_vertex(top_left,  {0.0, 0.0}, colour, rotation)
	push_vertex(bot_right, {1.0, 1.0}, colour, rotation)
	push_vertex(bot_left,  {0.0, 1.0}, colour, rotation)
	push_vertex(top_left,  {0.0, 0.0}, colour, rotation)
}

push_box_lines :: proc(pos: [2]f32, scale: [2]f32, colour: Colour, rotation: f32 = 0.0) {

	push_line(pos, pos + {scale.x, 0}, colour)
	push_line(pos + {scale.x, 0}, pos + scale, colour)
	push_line(pos + scale, pos + {0, scale.y}, colour)
	push_line(pos + {0, scale.y}, pos, colour)

}

push_box_lines2 :: proc(pos: [2]f32, scale: [2]f32, colour: Colour, rotation: f32 = 0.0) {

	push_line(pos, pos + {scale.x, 0}, colour)
	push_line(pos + {scale.x, 0}, pos + scale, colour)
	push_line(pos + scale, pos + {0, scale.y}, colour)
	push_line(pos + {0, scale.y}, pos, colour)

}


//NOTE: Possible issue here is that all our other draws are bottom left origins, this is center
//However this is much better for accuracy when scaling up currently
push_circle :: proc(pos: [2]f32, diameter: [2]f32, colour: Colour, rotation: f32 = 0.0) {
	texture := ctx.shape_texture_empty
	texture.mode = gl.TRIANGLES
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	two_pi := 2.0 * math.PI

	centre_x := pos.x + (diameter.x/2 * math.cos_f32(0))
	centre_y := pos.y + (diameter.y/2 * math.sin_f32(0))
	centre := [3]f32{centre_x, centre_y, 0.0}

	prev := centre + f32(diameter.x/2)

	for i in 0..=CIRCLE_SEGMENTS {
		circ_pos := f32(f64(i) * two_pi / f64(CIRCLE_SEGMENTS))
		x := pos.x + (diameter.x/2 * math.cos_f32(circ_pos))
		y := pos.y + (diameter.y/2 * math.sin_f32(circ_pos))
		z: f32 = 0.0
		curr := [3]f32{x, y, z}
		push_vertex(curr, {0,0}, colour)
		push_vertex(centre, {0,0}, colour)
		push_vertex(prev, {0,0}, colour)
		prev = curr
	}
}

push_polygon :: proc(pos: [2]f32, size: [2]f32, sides: int, colour: Colour, rotation: f32 = 0.0) {
	texture := ctx.shape_texture_empty
	texture.mode = gl.TRIANGLES
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	two_pi := 2.0 * math.PI

	centre_x := pos.x + (size.x/2 * math.cos_f32(0))
	centre_y := pos.y + (size.y/2 * math.sin_f32(0))
	centre := [3]f32{centre_x, centre_y, 0.0}

	prev := centre + size.xyx/2

	for i in 0..=sides {
		circ_pos := f32(f64(i) * two_pi / f64(sides))
		x := pos.x + (size.x/2 * math.cos_f32(circ_pos))
		y := pos.y + (size.y/2 * math.sin_f32(circ_pos))
		z: f32 = 0.0
		curr := [3]f32{x, y, z}
		push_vertex(curr, {0,0}, colour)
		push_vertex(centre, {0,0}, colour)
		push_vertex(prev, {0,0}, colour)
		prev = curr
	}
}

//TODO: This is missing 1 segment at the end?
push_circle_lines :: proc(pos: [2]f32, diameter: [2]f32, colour: Colour, rotation: f32 = 0.0) {
	texture := ctx.shape_texture_empty
	texture.mode = gl.TRIANGLE_FAN
	if should_commit(texture.hndl, texture.mode) {
		commit()
	}

	ctx.loaded_texture = texture

	two_pi := 2.0 * math.PI

	prev: [2]f32
	curr: [2]f32
	circ_pos := f32(f64(1) * two_pi / f64(CIRCLE_SEGMENTS))
	x := pos.x + (diameter.x/2 * math.cos_f32(circ_pos))
	y := pos.y + (diameter.y/2 * math.sin_f32(circ_pos))
	prev = {x, y}
	first := [2]f32{x, y}
	for i in 2..=CIRCLE_SEGMENTS {
		circ_pos := f32(f64(i) * two_pi / f64(CIRCLE_SEGMENTS))
		x = pos.x + (diameter.x/2 * math.cos_f32(circ_pos))
		y = pos.y + (diameter.y/2 * math.sin_f32(circ_pos))
		curr = [2]f32{x, y}
		push_line(prev, curr, colour)
		prev = curr
	}
	push_line(prev, first, colour)
}

//////////////////////
////TC: FONTS ////////
//////////////////////
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
push_text :: proc(text: string, pos: [2]f32, font_size: f32, font: Ducc_Font = ctx.default_font, colour: Colour = WHITE) {
	_pos := pos
	texture: Ducc_Texture_Atlas = {
		hndl = font.hndl,
		data = font.data,
		height = font.height,
		width = font.width,
		rows = font.rows,
		cols = font.cols,
		sprite_size = font.sprite_size,
		mode        = gl.TRIANGLES
	}
	i := 0
	for c in text {
		switch c {
		case '\n':
			_pos.y -= font_size
			i = 0
			continue
		}
		push_rune(c, {_pos.x + f32((i32(i) * i32(font_size))), _pos.y}, font_size, font, colour = colour)
		i += 1
	}
}

push_rune :: proc(c: rune, pos: [2]f32, font_size: f32, font: Ducc_Font = ctx.default_font, colour: Colour = WHITE) {
	_pos := pos
	texture: Ducc_Texture_Atlas = {
		hndl = font.hndl,
		data = font.data,
		height = font.height,
		width = font.width,
		rows = font.rows,
		cols = font.cols,
		sprite_size = font.sprite_size,
		mode        = gl.TRIANGLES
	}
	switch c {
	case '\n':
		_pos.y -= font_size
	}
	offset_c := i32(c) - font.offset //offset our character so it can be indexed into the array
	index_y    := offset_c / font.rows //find the row in our atlas from top to bottom
	adj_cols := ((font.cols) * i32(index_y)) //find the starting point for the row in our imaginary flat array
	normalized_offset := (i32(offset_c) - adj_cols) //normalize our char index to be 0 to (cols- 1) so we can index into the row
	push_sprite_atlas(texture, {_pos.x, _pos.y}, {font_size, font_size}, {i32(normalized_offset), i32(index_y)}, colour = colour)
}

//////////////////////
////TC: TEXTURES
//////////////////////
sprite_atlas_load :: proc(data: []u8, width, height:int, sprite_size: i32) -> Ducc_Texture_Atlas {
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
	texture_atlas.mode        = gl.TRIANGLES
	return texture_atlas
}

//Takes in position data, texture data to be drawn, and index into the atlas from top down
//i.e 0,0 will be top left. atlas.rows - 1, atlas.cols - 1 will be bottom right
//TODO: For non stb loaded images this is upside down
//TODO: Instead of using indices for getting the texture should use sizes
push_sprite_atlas :: proc(atlas: Ducc_Texture_Atlas, pos: [2]f32, scale: [2]f32, index: [2]i32, rotation: f32 = 0.0, colour: Colour = WHITE) {
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
	push_vertex({pos.x + scale.x, pos.y + scale.y, 0.0},{x_offset_plus_one, y_offset}, colour)
	push_vertex({pos.x + scale.x, pos.y, 0.0},{x_offset_plus_one, y_offset_minus_one}, colour)
	push_vertex({pos.x, pos.y + scale.y, 0.0},{x_offset, y_offset}, colour)
	push_vertex({pos.x + scale.x, pos.y, 0.0},{x_offset_plus_one, y_offset_minus_one}, colour)
	push_vertex({pos.x, pos.y, 0.0},{x_offset, y_offset_minus_one}, colour)
	push_vertex({pos.x, pos.y + scale.y, 0.0},{x_offset, y_offset}, colour)

}

//Read in some file name
//Return back data about the texture
sprite_load :: proc(data: []u8, width, height: int)  -> Ducc_Texture {
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
	texture.mode   = gl.TRIANGLES
	return texture
}

//Takes in position data, and texture data to be drawn
push_sprite :: proc(texture: Ducc_Texture, pos: [2]f32, scale: [2]f32, rotation: f32 = 0.0, flip := [2]bool{}, colour := WHITE) {
	if (ctx.loaded_texture.hndl != 0 && texture.hndl != ctx.loaded_texture.hndl) {
		commit()
	}

	ctx.loaded_texture = texture

	//TODO: This doesn't sit well with me 
	//	flip{false, false} == sprite is right side up
	push_vertex({pos.x + scale.x, pos.y + scale.y, 0.0}, {f32(i32(!flip.x)), 0.0}, colour)
	push_vertex({pos.x + scale.x, pos.y, 0.0},           {f32(i32(!flip.x)), 1.0}, colour)
	push_vertex({pos.x, pos.y + scale.y, 0.0},           {f32(i32(flip.x)), 0.0}, colour)
	push_vertex({pos.x + scale.x, pos.y, 0.0},           {f32(i32(!flip.x)), 1.0}, colour)
	push_vertex({pos.x, pos.y, 0.0},                     {f32(i32(flip.x)), 1.0}, colour)
	push_vertex({pos.x, pos.y + scale.y, 0.0},           {f32(i32(flip.x)), 0.0}, colour)
}

//////////////////////
/////TC: UTILS ///////
//////////////////////
push_vertex :: proc(pos_coords: [3]f32, uv_coords: [2]f32, colour: Colour, rotation: f32 = 0.0) {
	vertex: Vertex
	vertex.pos_coords = pos_coords
	vertex.texture_coords = uv_coords
	vertex.colour = colour_apply(colour)

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.batch_vertices_count) * size_of(Vertex),
		size_of(Vertex),
		&vertex,
	)
	ctx.batch_vertices_count += 1
}

@(private)
should_commit :: proc(hndl: u32, mode: u32) -> bool {
	return (ctx.loaded_texture.hndl != 0 && hndl != ctx.loaded_texture.hndl) ||
			(ctx.loaded_texture.mode != 0 && ctx.loaded_texture.mode != mode)
}

@(private)
colour_apply :: proc(colour: Colour) -> [4]f32 {
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.
	return {r, g, b, a}
}

when 1 == 0 {
colour_apply_hex :: proc(colour: Color) -> [4]f32 {
	colour := u32(colour)
	r := f32((colour >> 24) & 0xFF ) / 255.
	g := f32((colour >> 16) & 0xFF ) / 255.
	b := f32((colour >> 8) & 0xFF ) / 255.
	a := f32((colour) & 0xFF ) / 255.
	return {r, g, b, a}
}
}

commit :: proc() {
	if ctx.camera != nil {
		gl.UniformMatrix4fv(ctx.loaded_uniforms["view"].location, 1, false, &ctx.view_matrix[0, 0])
	}
	gl.BindTexture(gl.TEXTURE_2D, ctx.loaded_texture.hndl)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, ctx.loaded_texture.width, ctx.loaded_texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(ctx.loaded_texture.data))
	gl.GenerateMipmap(gl.TEXTURE_2D)
	/* blah := ctx.batch_vertices[:ctx.batch_vertices_count]
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.batch_vertices_count) * size_of(Vertex),
		size_of(ctx.batch_vertices[:ctx.batch_vertices_count]),
		&blah,
	) */
	gl.DrawArrays(ctx.loaded_texture.mode, 0, ctx.batch_vertices_count)
	ctx.batch_vertices_count = 0
}

vertex_attrib_apply :: proc() {
}
