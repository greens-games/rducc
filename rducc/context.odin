package rducc

import "vendor:glfw"
import gl "vendor:OpenGL"

Shader_Progams :: enum u8 {
	PRIMITIVE,
	TEXTURE,
	CIRCLE,
	CIRCLE_OUTLINE,
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

	time:                 f64,
	mouse_pos:            [2]f32,
	indices:              []u32,
	key_input_queue:      [u32(Key.COUNT)]Input_Action,


	//NOTE: This should be removed
	camera:               Camera,
}

//TODO: This probably shouldn't be a static global, maybe make it a pointer you can pass around when needed on init?
// That being said the consumer probably shouldn't care too much about this context it's more for the platform layer and/or renderer to use to do stuff
ctx: Context
