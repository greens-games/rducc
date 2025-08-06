package lib

import "vendor:glfw"
import gl "vendor:OpenGL"

Shader_Defaults :: enum {

}

Rducc_Context :: struct {
	window_hndl: glfw.WindowHandle,
	window_width: i32, 
	window_height: i32,
	program_cache: [10]u32,
	loaded_program: u32,
	loaded_uniforms: gl.Uniforms,

}

//TODO: This probably shouldn't be a static global, maybe make it a pointer you can pass around when needed on init?
// That being said the consumer probably shouldn't care too much about this context it's more for the platform layer and/or renderer to use to do stuff
ctx := Rducc_Context{}
