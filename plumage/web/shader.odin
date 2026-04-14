package plumage


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
	/* uniforms:    gl.Uniforms, */
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

