package rducc

import "core:time"
import gl "vendor:OpenGL"
import "core:fmt"

//TODO: Free uniforma data
shader_load :: proc(vs_shader, fs_shader: string) -> u32 {
	//TODO:manual shader loading, compiling, etc... (Makes debugging easier), use OpenGL/helpers.odin as example
	program_id, ok := gl.load_shaders_file(vs_shader, fs_shader)
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS: %v",gl.get_last_error_message()))
	}
	ctx.loaded_uniforms = gl.get_uniforms_from_program(program_id)
	shader_program: Shader_Progam = {
		program_id,
		gl.get_uniforms_from_program(program_id)
	}
	ctx.shader_cache[ctx.shader_cache_count] = shader_program
	ctx.shader_cache_count += 1
	gl.UseProgram(program_id)
	return program_id
}

uniforms_load :: proc() {
}

program_load :: proc(idx: Shader_Progams) {
	ctx.loaded_program = ctx.shader_cache[idx].hndl
	ctx.loaded_uniforms = ctx.shader_cache[idx].uniforms
	gl.UseProgram(ctx.loaded_program)
}
