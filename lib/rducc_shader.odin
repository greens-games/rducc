package lib

import gl "vendor:OpenGL"
import "core:fmt"

rducc_shader_load :: proc(vs_shader, fs_shader: string) -> u32 {
	//TODO: Cache the loaded program so we don't have to recompile everytime, OR manual shader loading, compiling, etc... (Makes debugging easier)
	program_id, ok := gl.load_shaders_file(vs_shader, fs_shader)
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS: %v",gl.get_last_error_message()))
	}
	gl.get_uniforms_from_program(program_id)
	gl.UseProgram(program_id)
	return program_id
}
