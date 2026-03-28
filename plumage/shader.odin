package plumage

import "core:time"
import "core:mem"
import gl "vendor:OpenGL"
import "core:fmt"

Attribute_Kind :: enum {
	F32,
	VEC2,
	VEC3,
	VEC4,
}

Var_Type :: union {
	Attribute_Kind
}

Shader_Progam :: struct {
	hndl:     u32,
	vao:      u32,
	vbo:      u32,
	uniforms: gl.Uniforms,
}

Shader_Var_Kind :: enum {
	ATTRIBUTE,
	UNIFORM,
}

Shader_Var :: struct {
	type:     Var_Type,
	size:     i32,
	location: u32,
}

//TODO: Free uniforma data
shader_load :: proc(vs_shader, fs_shader: string) -> u32 {

	//TODO:manual shader loading, compiling, etc... (Makes debugging easier), use OpenGL/helpers.odin as example
	program_id, ok := gl.load_shaders_file(vs_shader, fs_shader)
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS: %v",gl.get_last_error_message()))
	}
	ctx.loaded_uniforms = gl.get_uniforms_from_program(program_id)
	shader_program := shader_parse_attributes(program_id)
	ctx.shader_cache[ctx.shader_cache_count] = shader_program
	ctx.shader_cache_count += 1
	gl.UseProgram(program_id)
	return program_id
}

shader_load_from_mem :: proc(vs_shader, fs_shader: []byte) -> u32 {

	program_id, ok := gl.load_shaders_source(string(vs_shader), string(fs_shader))
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS: %v",gl.get_last_error_message()))
	}
	//TODO: Go through generated program and grab all attributes to create some shader Program
	//Add that to the shader cache
	/*
	Steps:
		getProgramiv pname = (gl.ACTIVE_ATTRIBUTES, or gl.ACTIVE_UNIFORMS, etc...)
		for each active thing
			get current active
			get current location
			create struct based on what's needed there
	*/
	shader_program := shader_parse_attributes(program_id)
	ctx.shader_cache[ctx.shader_cache_count] = shader_program
	ctx.shader_cache_count += 1
	gl.UseProgram(program_id)
	return program_id
}

shader_parse_attributes :: proc(program_id: u32) -> Shader_Progam {
	shader_program: Shader_Progam 
	num_attrs: i32
	name_buf: [256]u8
	gl.GetProgramiv(program_id, gl.ACTIVE_ATTRIBUTES, &num_attrs)
	attributes := make_dynamic_array([dynamic]Shader_Var)
	stride: i32
	for index in 0..<num_attrs {
		length, size: i32
		type: u32
		gl.GetActiveAttrib(program_id, u32(index), len(name_buf), &length, &size, &type, raw_data(name_buf[:]))
		loc := gl.GetAttribLocation(program_id, cstring(raw_data(name_buf[:length])))
		plumage_kind: Attribute_Kind
		switch type {
		case gl.FLOAT: plumage_kind = .F32
		case gl.FLOAT_VEC2: plumage_kind = .VEC2
		case gl.FLOAT_VEC3: plumage_kind = .VEC3
		case gl.FLOAT_VEC4: plumage_kind = .VEC4
		case: panic("unsupported attribute type")
		}
		//Construct struct
		//get actual size
		attribute := Shader_Var {
			type = plumage_kind,
			location = u32(loc),
		}
		//TODO: We will want to support more attribute types
		switch plumage_kind {
		case .F32: attribute.size = 1
		case .VEC2: attribute.size = 2
		case .VEC3: attribute.size = 3
		case .VEC4: attribute.size = 4
		}
		append(&attributes, attribute)
		stride += attribute.size * size_of(f32)
	}
	//Do the vertex attrib pointer stuff
	offset := 0

	gl.GenBuffers(1, &shader_program.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, shader_program.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, mem.Megabyte, nil, gl.DYNAMIC_DRAW)
	gl.GenVertexArrays(1, &shader_program.vao)
	gl.BindVertexArray(shader_program.vao)

	for attr in attributes {
		gl.EnableVertexAttribArray(attr.location)
		//TODO: We will want to support more attribute types not just gl.FLOAT
		gl.VertexAttribPointer(attr.location, attr.size, gl.FLOAT, false, stride, uintptr(offset * size_of(f32)))
		offset += int(attr.size)
	}
	ctx.loaded_uniforms = gl.get_uniforms_from_program(program_id)
	shader_program.hndl = program_id
	shader_program.uniforms = gl.get_uniforms_from_program(program_id)
	return shader_program
}
