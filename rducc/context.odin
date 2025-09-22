package rducc

import "vendor:glfw"
import gl "vendor:OpenGL"

Shader_Progams :: enum u8 {
	PRIMITIVE,
	TEXTURE,
	CIRCLE,
}

Shader_Progam :: struct {
	hndl: u32,
	uniforms: gl.Uniforms,
}

Context :: struct {
	window_hndl:          glfw.WindowHandle,
	window_width:         i32, 
	window_height:        i32,
	program_cache:        [10]u32,
	loaded_program:       u32,
	loaded_uniforms:      gl.Uniforms,
	shader_cache:         [10]Shader_Progam,
	shader_cache_count:   u32,
	gl_ebo:               u32,
	gl_vbo:               u32,
	gl_vao:               u32,
	time:                 f64,
	mouse_pos:            [2]f32,
	indices:              []u32,
}

//TODO: This probably shouldn't be a static global, maybe make it a pointer you can pass around when needed on init?
// That being said the consumer probably shouldn't care too much about this context it's more for the platform layer and/or renderer to use to do stuff
ctx: Context
