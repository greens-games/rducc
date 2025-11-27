package rducc

import "vendor:glfw"
import gl "vendor:OpenGL"

Shader_Progams :: enum u8 {
	PRIMITIVE,
	CIRCLE,
	CIRCLE_OUTLINE,
	TEXTURE,
	GRID,
}

Shader_Progam :: struct {
	hndl: u32,
	uniforms: gl.Uniforms,
}

Context :: struct {
	window_hndl:          glfw.WindowHandle,
	window_width:         i32, 
	window_height:        i32,

	//NOTE: Default shaders to renderer uses internally
	program_cache:        [10]u32,
	shader_cache:         [10]Shader_Progam,
	shader_cache_count:   u32,
	loaded_program:       u32,
	loaded_uniforms:      gl.Uniforms,
	buffer_offset:        int,

	//NOTE: Batching stuff
	num_vertices:         i32,
	box_vertices:         i32,
	circle_vertices:      i32,
	texture_vertices:     i32,
	outline_vertices:     i32,
	loaded_buffer:        Shader_Progams,

	//NOTE: Misc 
	time:                 f64,
	mouse_pos:            [2]f32,
	indices:              []u32,
	key_input_queue:      [u32(Key.COUNT)]Input_Action,

	//Textures
	levels:               i32,
	curr_level:           i32,

	//NOTE: This should be removed
	camera:               Camera,
}

Ducc_Texture :: struct {
	hndl:   u32,
	data:   [^]byte,
	height: i32,
	width:  i32,
	level:  i32,
}

//TODO: This probably shouldn't be a static global, maybe make it a pointer you can pass around when needed on init?
// That being said the consumer probably shouldn't care too much about this context it's more for the platform layer and/or renderer to use to do stuff
ctx: Context
