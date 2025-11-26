package rducc

import "base:runtime"
import "core:c"
import "core:container/lru"
import "core:image"
import "core:math"
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
KB :: 1024
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

//TODO: We may want to create a struct for our vertices so we can more easily send more data to the GPU
//I believe this mainly affects sending attributes to shaders, may also minorly affect the DrawCalls and BufferData but I don't 100% remember
vertices_index_box := [?]Vertex {
	{pos_coords = {1.0,   1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
	{pos_coords = {1.0,  -1.0, 1.0}},
	{pos_coords = {-1.0, -1.0, 1.0}},
	{pos_coords = {-1.0,  1.0, 1.0}},
}


Vert_Info :: struct {
	pos:      [2]f32,
	scale:    [2]f32,
	rotation: f32,
	radius:   f32,
}

Frag_Info :: struct {
	colour: Colour,
}

Vertex :: struct {
	pos_coords:     [3]f32,
	texture_coords: [2]f32,
	pos:            [3]f32,
	scale:          [2]f32,
	rotation:       f32,
	colour:         [4]f32,
}

EBO, VAO, VBO: u32
VBO_MULTI: [4]u32

renderer_init :: proc() {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address) //required for proc address stuff
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
	gl.DebugMessageCallback(debug_proc_t, {})
	/* gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) */
	//Can add filters here
	gl.DebugMessageControl(
		gl.DEBUG_SOURCE_API,
		gl.DEBUG_TYPE_ERROR,
		gl.DEBUG_SEVERITY_HIGH,
		0,
		nil,
		gl.TRUE,
	)
	/* gl.DebugMessageControl(gl.DEBUG_SOURCE_API, gl.DEBUG_TYPE_ERROR, gl.DEBUG_SEVERITY_MEDIUM, 0, nil, gl.TRUE) */

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	ctx.indices = make_slice([]u32, 6)
	ctx.indices[0] = 0
	ctx.indices[1] = 1
	ctx.indices[2] = 3
	ctx.indices[3] = 1
	ctx.indices[4] = 2
	ctx.indices[5] = 3

	//TODO: Generate and store a buffer for each batch type?
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(4, raw_data(&VBO_MULTI))
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[0])
	gl.BufferData(gl.ARRAY_BUFFER, KB * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[1])
	gl.BufferData(gl.ARRAY_BUFFER, KB * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[2])
	gl.BufferData(gl.ARRAY_BUFFER, KB * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindVertexArray(VAO)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)
	gl.EnableVertexAttribArray(4)
	gl.EnableVertexAttribArray(5)

	shader_load("res/vert_2d.glsl", "res/frag_primitive.glsl")
	shader_load("res/vert_2d.glsl", "res/circle_shader.glsl")
	shader_load("res/vert_2d.glsl", "res/circle_outline_shader.glsl")
	shader_load("res/vert_2d.glsl", "res/frag_texture_array.glsl")
	shader_load("res/vert_grid.glsl", "res/grid.glsl")
	projection := glm.mat4Ortho3d(
		0.0,
		f32(ctx.window_width),
		0.0,
		f32(ctx.window_height),
		-100.0,
		100.0,
	)
	program_load(Shader_Progams.CIRCLE)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0])
	program_load(Shader_Progams.PRIMITIVE)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0])
	program_load(Shader_Progams.TEXTURE)
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
	/* switch source {
        case gl.DEBUG_SOURCE_API:             fmt.println("Source: API")
        case gl.DEBUG_SOURCE_WINDOW_SYSTEM:   fmt.println("Source: Window System")
        case gl.DEBUG_SOURCE_SHADER_COMPILER: fmt.println("Source: Shader Compiler")
        case gl.DEBUG_SOURCE_THIRD_PARTY:     fmt.println("Source: Third Party")
        case gl.DEBUG_SOURCE_APPLICATION:     fmt.println("Source: Application")
        case gl.DEBUG_SOURCE_OTHER:           fmt.println("Source: Other")
    } */

	switch (type) {
	case gl.DEBUG_TYPE_ERROR:
		fmt.println("Type: Error")
		fmt.println("MESSAGE: ", message)
	/* case gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR: fmt.println("Type: Deprecated Behaviour")
        case gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR:  fmt.println("Type: Undefined Behaviour")
        case gl.DEBUG_TYPE_PORTABILITY:         fmt.println("Type: Portability")
        case gl.DEBUG_TYPE_PERFORMANCE:         fmt.println("Type: Performance")
        case gl.DEBUG_TYPE_MARKER:              fmt.println("Type: Marker")
        case gl.DEBUG_TYPE_PUSH_GROUP:          fmt.println("Type: Push Group")
        case gl.DEBUG_TYPE_POP_GROUP:           fmt.println("Type: Pop Group")
        case gl.DEBUG_TYPE_OTHER:               fmt.println("Type: Other") */
	}
	/* switch (severity) {
        case gl.DEBUG_SEVERITY_HIGH:         fmt.println("Severity: high")
        case gl.DEBUG_SEVERITY_MEDIUM:       fmt.println("Severity: medium")
        case gl.DEBUG_SEVERITY_LOW:          fmt.println("Severity: low")
        case gl.DEBUG_SEVERITY_NOTIFICATION: fmt.println("Severity: notification")
    } */

}


//NOTE: This is exactly how raylib does their ClearBackground logic
renderer_background_clear :: proc(color: Colour) {
	r := f32(color.r) / 255.
	g := f32(color.g) / 255.
	b := f32(color.b) / 255.
	a := f32(color.a) / 255.
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

renderer_pixel :: proc(pos: [3]f32, colour: Colour) {
	vertices := [?]f32{-1.0, -1.0, 0.0}
	indices := [?]f32{0}
	/* gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32), &indices, gl.DYNAMIC_DRAW) */
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	renderer_mvp_apply(pos)
	gl.DrawArrays(gl.POINTS, 0, len(vertices))
	/* gl.DrawElements(gl.TRIANGLES, 1, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
}

renderer_box :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[i32(Shader_Progams.PRIMITIVE)])

	v := vertices_index_box
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.

	for &vert in v {
		vert.pos = pos
		vert.scale = scale
		vert.rotation = rotation
		vert.colour = renderer_colour_apply(colour)
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.box_vertices) * size_of(Vertex),
		size_of(v),
		&v,
	)

	ctx.box_vertices += len(vertices_index_box)
}

renderer_box_lines :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	//TODO: This could be indices if we can figure out how to not get the errors?
	vertices := [?]Vertex {
		{pos_coords = {1.0, 1.0, 0.0}},
		{pos_coords = {1.0, -1.0, 0.0}},
		{pos_coords = {1.0, -1.0, 0.0}},
		{pos_coords = {-1.0, -1.0, 0.0}},
		{pos_coords = {-1.0, -1.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}},
		{pos_coords = {1.0, 1.0, 0.0}},
	}
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	renderer_mvp_apply(pos, scale, rotation)
	renderer_colour_apply(colour)
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.LINES, 0, 8)
}

//NOTE: For polygons we need to define the vertices we are doing and adjust scaling based on that I think
renderer_polygon :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	vertices := [?]f32{0.0, 1.0, 0.0, -0.5, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.0, 0.0}
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	renderer_colour_apply(colour)
	/* renderer_mvp_apply(vert_info, frag_info) */
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.DrawArrays(gl.LINES, 3, 2)
}

renderer_polygon_sides :: proc(
	pos: [3]f32,
	scale: [2]f32,
	sides: i32,
	rotation: f32 = 0.0,
	colour := PINK,
) {
	assert(sides < 20)
	vertices: [20]Vertex
	segments := sides
	two_pi := 2.0 * math.PI

	vertices[0] = {
		pos_coords = {pos.x, pos.y, 0.0},
	}

	for i in 0 ..= segments {
		circ_pos := f32(f64(i) * two_pi / f64(segments))
		vertices[i].pos_coords.x = pos.x + (scale.x * math.cos_f32(circ_pos))
		vertices[i].pos_coords.y = pos.y + (scale.y * math.sin_f32(circ_pos))
		vertices[i].pos_coords.z = 0.0
	}

	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	/* gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices_temp), &vertices_temp, gl.DYNAMIC_DRAW) */
	renderer_colour_apply(colour)
	renderer_mvp_apply(pos, scale, rotation)
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(segments + 1))
	/* gl.DrawArrays(gl.TRIANGLE_FAN, 0, 5) */
}

renderer_circle_vertices :: proc(
	pos: [3]f32,
	radius: [2]f32,
	rotation: f32 = 0.0,
	colour := PINK,
) {
	vertices: [21]Vertex
	segments := len(vertices) - 1
	two_pi := 2.0 * math.PI

	vertices[0] = {
		pos_coords = {0.0, 0.0, 0.0},
	}

	for i in 0 ..= segments {
		circ_pos := f32(f64(i) * two_pi / f64(segments))
		vertices[i].pos_coords.x = 0.0 + (1.0 * math.cos_f32(circ_pos))
		vertices[i].pos_coords.y = 0.0 + (1.0 * math.sin_f32(circ_pos))
		vertices[i].pos_coords.z = 0.0
	}

	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	renderer_colour_apply(colour)
	renderer_mvp_apply(pos, radius, rotation)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(segments + 1))
}

renderer_circle_shader :: proc(pos: [3]f32, radius: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[i32(Shader_Progams.CIRCLE)])

	v := vertices_index_box
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.

	for &vert in v {
		vert.pos      = pos
		vert.scale    = radius
		vert.rotation = rotation
		vert.colour   = renderer_colour_apply(colour)
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.circle_vertices) * size_of(Vertex),
		size_of(v),
		&v,
	)

	ctx.circle_vertices += len(vertices_index_box)
}

renderer_circle_outline_shader :: proc(
	pos: [3]f32,
	radius: [2]f32,
	rotation: f32 = 0.0,
	colour := PINK,
) {
	program_load(Shader_Progams.CIRCLE_OUTLINE)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(vertices_index_box),
		&vertices_index_box,
		gl.DYNAMIC_DRAW,
	)
	renderer_mvp_apply(pos, radius, rotation)
	renderer_colour_apply(colour)

	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, raw_data(ctx.indices))
	program_load(Shader_Progams.PRIMITIVE)
}

//Read in some file name
//Return back data about the texture
renderer_sprite_load :: proc(f_name: cstring)  -> Ducc_Texture {
	//NOTE: Could also do BMP file parsing if I wanted to do my own stuff
	height, width, channels_in_file: i32
	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(f_name, &height, &width, &channels_in_file, 4)
	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)
	gl.GetTextureHandleARB(texture_hndl)

	texture: Ducc_Texture
	texture.data   = data
	texture.height = height
	texture.width  = width
	texture.hndl   = texture_hndl
	return texture
}

//Read in some file
//Allocate Texture to Texture Array
//Return texture data
renderer_sprite_texture_array_load :: proc(f_name: cstring)  -> Ducc_Texture {
	//NOTE: Could also do BMP file parsing if I wanted to do my own stuff
	height, width, channels_in_file: i32
	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(f_name, &height, &width, &channels_in_file, 4)
	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)
	gl.GetTextureHandleARB(texture_hndl)

	texture: Ducc_Texture
	texture.data   = data
	texture.height = height
	texture.width  = width
	texture.hndl   = texture_hndl
	return texture
}

//Takes in position data, and texture data to be drawn
renderer_sprite_texture_array_draw :: proc(texture: Ducc_Texture, pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := WHITE) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[2])
	gl.BindTexture(gl.TEXTURE_2D, texture.hndl)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.height, texture.width, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture.data)
	vertices := [?]Vertex {
		//1
		{pos_coords = {1.0, 1.0, 0.0}, texture_coords = {1.0, 1.0}},
		{pos_coords = {1.0, -1.0, 0.0}, texture_coords = {1.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}, texture_coords = {0.0, 1.0}},
		//2
		{pos_coords = {1.0, -1.0, 0.0}, texture_coords = {1.0, 0.0}},
		{pos_coords = {-1.0, -1.0, 0.0}, texture_coords = {0.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}, texture_coords = {0.0, 1.0}},
	}

	for &vert in vertices {
		vert.pos      = pos
		vert.scale    = scale
		vert.rotation = rotation
		vert.colour   = renderer_colour_apply(colour)
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.texture_vertices) * size_of(Vertex),
		size_of(vertices),
		&vertices,
	)
	ctx.texture_vertices += len(vertices)
}

renderer_sprite_atlas_load :: proc(f_name: cstring) -> Ducc_Texture {
	//NOTE: Could also do BMP file parsing if I wanted to do my own stuff
	height, width, channels_in_file: i32
	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(f_name, &height, &width, &channels_in_file, 4)

	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture_hndl)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	texture: Ducc_Texture
	texture.data   = data
	texture.height = height
	texture.width  = width
	texture.hndl   = texture_hndl
	return texture
}

//Takes in position data, and texture data to be drawn
renderer_sprite_draw :: proc(texture: Ducc_Texture, pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := WHITE) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[2])
	gl.BindTexture(gl.TEXTURE_2D, texture.hndl)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.height, texture.width, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture.data)
	vertices := [?]Vertex {
		//1
		{pos_coords = {1.0, 1.0, 0.0}, texture_coords = {1.0, 1.0}},
		{pos_coords = {1.0, -1.0, 0.0}, texture_coords = {1.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}, texture_coords = {0.0, 1.0}},
		//2
		{pos_coords = {1.0, -1.0, 0.0}, texture_coords = {1.0, 0.0}},
		{pos_coords = {-1.0, -1.0, 0.0}, texture_coords = {0.0, 0.0}},
		{pos_coords = {-1.0, 1.0, 0.0}, texture_coords = {0.0, 1.0}},
	}

	for &vert in vertices {
		vert.pos      = pos
		vert.scale    = scale
		vert.rotation = rotation
		vert.colour   = renderer_colour_apply(colour)
	}

	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(ctx.texture_vertices) * size_of(Vertex),
		size_of(vertices),
		&vertices,
	)
	ctx.texture_vertices += len(vertices)
}

renderer_grid_draw :: proc(colour := PINK) {
	program_load(Shader_Progams.GRID)
	renderer_colour_apply(colour)
	gl.Uniform1f(ctx.loaded_uniforms["size"].location, 160.0)
	gl.Uniform2f(
		ctx.loaded_uniforms["u_resolution"].location,
		f32(ctx.window_width),
		f32(ctx.window_height),
	)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(vertices_index_box),
		&vertices_index_box,
		gl.DYNAMIC_DRAW,
	)
	renderer_colour_apply(colour)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, raw_data(ctx.indices))
	program_load(Shader_Progams.PRIMITIVE)
}

renderer_colour_apply :: proc(colour: Colour) -> [4]f32 {
	//TODO: do colour in separate function
	r := f32(colour.r) / 255.
	g := f32(colour.g) / 255.
	b := f32(colour.b) / 255.
	a := f32(colour.a) / 255.
	//TODO: Colour can probably be an attribute rather than uniform
	return {r, g, b, a}
}

//NOTE: Unused for now
renderer_mvp_apply :: proc(pos: [3]f32, scale := [2]f32{1.0, 1.0}, rotation: f32 = 0.0) {

	camera_scale := ctx.camera.zoom > 0.0 ? ctx.camera.zoom : 1.0
	//TODO: Apply zoom to projection matrix
	projection := glm.mat4Ortho3d(
		0.0,
		f32(ctx.window_width) / camera_scale,
		0.0,
		f32(ctx.window_height) / camera_scale,
		-1.0,
		1.0,
	)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location, 1, false, &projection[0, 0])

	adjusted_scale := [3]f32{scale.x / 2., scale.y / 2., 0.}
	i := glm.identity(glm.mat4)
	t := glm.mat4Translate({pos.x + adjusted_scale.x, pos.y + adjusted_scale.y, 0.})
	s := glm.mat4Scale({scale.x / 2., scale.y / 2., 1.0})
	rot := glm.mat4Rotate({0.0, 0.0, 1.0}, glm.radians(rotation))
	i *= t
	i *= rot
	i *= s
	/* gl.UniformMatrix4fv(ctx.loaded_uniforms["transform"].location, 1, false, &i[0, 0]) */
}

renderer_draw :: proc() {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[0])
	renderer_vertex_attrib_apply()
	program_load(.PRIMITIVE)
	gl.DrawArrays(gl.TRIANGLES, 0, ctx.box_vertices)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[1])
	renderer_vertex_attrib_apply()
	program_load(.CIRCLE)
	gl.DrawArrays(gl.TRIANGLES, 0, ctx.circle_vertices)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[2])
	renderer_vertex_attrib_apply()
	program_load(.TEXTURE)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	gl.DrawArrays(gl.TRIANGLES, 0, ctx.texture_vertices)

	ctx.box_vertices = 0
	ctx.circle_vertices = 0
	ctx.texture_vertices = 0
}

renderer_vertex_attrib_apply :: proc() {
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), (0 * size_of(f32)))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), (3 * size_of(f32)))
	gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(Vertex), (5 * size_of(f32)))
	gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Vertex), (8 * size_of(f32)))
	gl.VertexAttribPointer(4, 1, gl.FLOAT, false, size_of(Vertex), (10 * size_of(f32)))
	gl.VertexAttribPointer(5, 4, gl.FLOAT, false, size_of(Vertex), (11 * size_of(f32)))
}
