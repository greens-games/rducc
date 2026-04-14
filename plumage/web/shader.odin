package plumage

import gl "vendor:wasm/WebGL"
import "core:fmt"
import "core:strings"

//NOTE: This is just ripped from vendor:OpenGL

Uniform_Type :: enum i32 {
	FLOAT      = 0x1406,
	FLOAT_VEC2 = 0x8B50,
	FLOAT_VEC3 = 0x8B51,
	FLOAT_VEC4 = 0x8B52,

	DOUBLE      = 0x140A,
	DOUBLE_VEC2 = 0x8FFC,
	DOUBLE_VEC3 = 0x8FFD,
	DOUBLE_VEC4 = 0x8FFE,

	INT      = 0x1404,
	INT_VEC2 = 0x8B53,
	INT_VEC3 = 0x8B54,
	INT_VEC4 = 0x8B55,

	UNSIGNED_INT      = 0x1405,
	UNSIGNED_INT_VEC2 = 0x8DC6,
	UNSIGNED_INT_VEC3 = 0x8DC7,
	UNSIGNED_INT_VEC4 = 0x8DC8,

	BOOL      = 0x8B56,
	BOOL_VEC2 = 0x8B57,
	BOOL_VEC3 = 0x8B58,
	BOOL_VEC4 = 0x8B59,

	FLOAT_MAT2   = 0x8B5A,
	FLOAT_MAT3   = 0x8B5B,
	FLOAT_MAT4   = 0x8B5C,
	FLOAT_MAT2x3 = 0x8B65,
	FLOAT_MAT2x4 = 0x8B66,
	FLOAT_MAT3x2 = 0x8B67,
	FLOAT_MAT3x4 = 0x8B68,
	FLOAT_MAT4x2 = 0x8B69,
	FLOAT_MAT4x3 = 0x8B6A,

	DOUBLE_MAT2   = 0x8F46,
	DOUBLE_MAT3   = 0x8F47,
	DOUBLE_MAT4   = 0x8F48,
	DOUBLE_MAT2x3 = 0x8F49,
	DOUBLE_MAT2x4 = 0x8F4A,
	DOUBLE_MAT3x2 = 0x8F4B,
	DOUBLE_MAT3x4 = 0x8F4C,
	DOUBLE_MAT4x2 = 0x8F4D,
	DOUBLE_MAT4x3 = 0x8F4E,

	SAMPLER_1D                   = 0x8B5D,
	SAMPLER_2D                   = 0x8B5E,
	SAMPLER_3D                   = 0x8B5F,
	SAMPLER_CUBE                 = 0x8B60,
	SAMPLER_1D_SHADOW            = 0x8B61,
	SAMPLER_2D_SHADOW            = 0x8B62,
	SAMPLER_1D_ARRAY             = 0x8DC0,
	SAMPLER_2D_ARRAY             = 0x8DC1,
	SAMPLER_1D_ARRAY_SHADOW      = 0x8DC3,
	SAMPLER_2D_ARRAY_SHADOW      = 0x8DC4,
	SAMPLER_2D_MULTISAMPLE       = 0x9108,
	SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B,
	SAMPLER_CUBE_SHADOW          = 0x8DC5,
	SAMPLER_BUFFER               = 0x8DC2,
	SAMPLER_2D_RECT              = 0x8B63,
	SAMPLER_2D_RECT_SHADOW       = 0x8B64,

	INT_SAMPLER_1D                   = 0x8DC9,
	INT_SAMPLER_2D                   = 0x8DCA,
	INT_SAMPLER_3D                   = 0x8DCB,
	INT_SAMPLER_CUBE                 = 0x8DCC,
	INT_SAMPLER_1D_ARRAY             = 0x8DCE,
	INT_SAMPLER_2D_ARRAY             = 0x8DCF,
	INT_SAMPLER_2D_MULTISAMPLE       = 0x9109,
	INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C,
	INT_SAMPLER_BUFFER               = 0x8DD0,
	INT_SAMPLER_2D_RECT              = 0x8DCD,

	UNSIGNED_INT_SAMPLER_1D                   = 0x8DD1,
	UNSIGNED_INT_SAMPLER_2D                   = 0x8DD2,
	UNSIGNED_INT_SAMPLER_3D                   = 0x8DD3,
	UNSIGNED_INT_SAMPLER_CUBE                 = 0x8DD4,
	UNSIGNED_INT_SAMPLER_1D_ARRAY             = 0x8DD6,
	UNSIGNED_INT_SAMPLER_2D_ARRAY             = 0x8DD7,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE       = 0x910A,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D,
	UNSIGNED_INT_SAMPLER_BUFFER               = 0x8DD8,
	UNSIGNED_INT_SAMPLER_2D_RECT              = 0x8DD5,

	IMAGE_1D                   = 0x904C,
	IMAGE_2D                   = 0x904D,
	IMAGE_3D                   = 0x904E,
	IMAGE_2D_RECT              = 0x904F,
	IMAGE_CUBE                 = 0x9050,
	IMAGE_BUFFER               = 0x9051,
	IMAGE_1D_ARRAY             = 0x9052,
	IMAGE_2D_ARRAY             = 0x9053,
	IMAGE_CUBE_MAP_ARRAY       = 0x9054,
	IMAGE_2D_MULTISAMPLE       = 0x9055,
	IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056,

	INT_IMAGE_1D                   = 0x9057,
	INT_IMAGE_2D                   = 0x9058,
	INT_IMAGE_3D                   = 0x9059,
	INT_IMAGE_2D_RECT              = 0x905A,
	INT_IMAGE_CUBE                 = 0x905B,
	INT_IMAGE_BUFFER               = 0x905C,
	INT_IMAGE_1D_ARRAY             = 0x905D,
	INT_IMAGE_2D_ARRAY             = 0x905E,
	INT_IMAGE_CUBE_MAP_ARRAY       = 0x905F,
	INT_IMAGE_2D_MULTISAMPLE       = 0x9060,
	INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061,

	UNSIGNED_INT_IMAGE_1D                   = 0x9062,
	UNSIGNED_INT_IMAGE_2D                   = 0x9063,
	UNSIGNED_INT_IMAGE_3D                   = 0x9064,
	UNSIGNED_INT_IMAGE_2D_RECT              = 0x9065,
	UNSIGNED_INT_IMAGE_CUBE                 = 0x9066,
	UNSIGNED_INT_IMAGE_BUFFER               = 0x9067,
	UNSIGNED_INT_IMAGE_1D_ARRAY             = 0x9068,
	UNSIGNED_INT_IMAGE_2D_ARRAY             = 0x9069,
	UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY       = 0x906A,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE       = 0x906B,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C,

	UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB,
}

Uniform_Info :: struct {
	location: i32,
	size:     i32,
	kind:     Uniform_Type,
	name:     string, // NOTE: This will need to be freed
}

Uniforms :: map[string]Uniform_Info

Attribute_Kind :: enum {
	F32,
	VEC2,
	VEC3,
	VEC4,
}

Uniform_Kind :: enum {
	MATRIX_4,
	VEC4_F32,
}

Var_Type :: union {
	Attribute_Kind
}

Shader_Progam :: struct {
	id:          u32,
	hndl:        u32,
	vao:         u32,
	vertex_size: i32,
	uniforms:    Uniforms,
}

Shader_Var_Kind :: enum {
	ATTRIBUTE,
	UNIFORM,
}

Shader_Var :: struct {
	type:        Var_Type,
	size:        i32,
	location:    u32,
}

//TODO: Free uniforma data
shader_load :: proc(vs_shader, fs_shader: string) -> Shader_Progam {

	//TODO:manual shader loading, compiling, etc... (Makes debugging easier), use OpenGL/helpers.odin as example
	program_id, ok := gl.load_shaders_file(vs_shader, fs_shader)
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS:"))
	}
	shader_program := shader_parse_attributes(program_id)
	ctx.shader_cache[ctx.shader_cache_count] = shader_program
	ctx.shader_cache_count += 1
	/* gl.UseProgram(program_id) */
	return shader_program
}

shader_load_from_mem :: proc(vs_shader, fs_shader: []byte) -> Shader_Progam {

	program_id, ok := gl.load_shaders_source(string(vs_shader), string(fs_shader))
	if !ok {
		panic(fmt.tprintfln("FAILED TO LOAD SHADERS:"))
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
	/* gl.UseProgram(program_id) */
	return shader_program
}

//TODO: probably some cleanup can be done here
shader_parse_attributes :: proc(program_id: u32) -> Shader_Progam {
	program_id := gl.Program(program_id)
	shader_program: Shader_Progam 
	name_buf: [256]u8
	num_attrs := gl.GetProgramParameter(program_id, gl.ACTIVE_ATTRIBUTES)
	attributes := make_dynamic_array([dynamic]Shader_Var)
	stride: i32
	for index in 0..<num_attrs {
		length, size: i32
		type: u32
		attrib_info := gl.GetActiveAttrib(program_id, u32(index), context.temp_allocator)
		loc := gl.GetAttribLocation(program_id, attrib_info.name)
		plumage_kind: Attribute_Kind
		switch attrib_info.type {
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
		stride += attribute.size * size_of(f32)
		append(&attributes, attribute)
	}
	//Do the vertex attrib pointer stuff
	offset := 0

	shader_program.vao = u32(gl.CreateVertexArray())
	gl.BindVertexArray(gl.VertexArrayObject(shader_program.vao))

	for attr in attributes {
		gl.EnableVertexAttribArray(i32(attr.location))
		//TODO: We will want to support more attribute types not just gl.FLOAT
		gl.VertexAttribPointer(i32(attr.location), int(attr.size), gl.FLOAT, false, int(stride), uintptr(offset * size_of(f32)))
		offset += int(attr.size)
	}
	//NOTE: Could maybe change this to be my own uniform loading but this should work fine for now
	shader_program.uniforms = get_uniforms_from_program(program_id)
	shader_program.hndl = u32(program_id)
	shader_program.vertex_size = stride
	shader_program.id = ctx.shader_cache_count
	return shader_program
}

//NOTE: This is ripped straight from vendor:OpenGL
@(private)
get_uniforms_from_program :: proc(program: gl.Program) -> (uniforms: Uniforms) {
	uniform_count: i32
	uniform_count = gl.GetProgramParameter(program, gl.ACTIVE_UNIFORMS)

	if uniform_count > 0 {
		reserve(&uniforms, int(uniform_count))
	}

	for i in 0..<uniform_count {
		uniform_info: Uniform_Info

		length: i32
		cname: [256]u8
		active_info := gl.GetActiveUniform(program, u32(i), context.temp_allocator)

		uniform_info.location = gl.GetUniformLocation(program, active_info.name)
		uniform_info.name = strings.clone(string(cname[:length])) // @NOTE: These need to be freed
		uniforms[uniform_info.name] = uniform_info
	}

	return uniforms
}

/* shader_uniform_value_set :: proc(name: string, kind: Uniform_Kind, value: rawptr) {

	loc := ctx.loaded_shader.uniforms[name].location //TODO: Replace this with loaded shader
	switch kind {
	case .MATRIX_4:
		_val := (cast(^matrix[4, 4]f32)value)^
		gl.UniformMatrix4fv(loc, 1, false, &_val[0, 0])
	case .VEC4_F32:
		_val := (cast(^[4]f32)value)^
		gl.Uniform4fv(loc, 1, raw_data(_val[:]))
	case: panic(fmt.tprintfln("Unsupported Matrix type: %v", kind))
	}

} */

