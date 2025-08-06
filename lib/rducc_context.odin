package lib

import "vendor:glfw"
import gl "vendor:OpenGL"

Rducc_Context :: struct {
	window_hndl: glfw.WindowHandle,
	loaded_program: u32,
	loaded_uniforms: gl.Uniforms,
}

ctx := Rducc_Context{}
