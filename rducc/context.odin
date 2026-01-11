package rducc

import "core:mem/virtual"
import "core:mem"
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
	//NOTE: Window
	window_hndl:          glfw.WindowHandle,
	window_width:         i32, 
	window_height:        i32,

	//NOTE: Default shaders to renderer uses internally
	program_cache:        [10]u32, //Could be dynamic
	shader_cache:         [10]Shader_Progam, //Could be dynamic
	shader_cache_count:   u32,
	loaded_program:       u32,
	loaded_uniforms:      gl.Uniforms,
	//TODO: default shape texture (big texture that is all white)
	shape_texture_empty:  Ducc_Texture,

	//NOTE: Batching stuff
	active_render_group:  ^Render_Group,
	active_vao:           u32,
	batch_vertices_count: i32,
	batch_vertices:       [DEFAULT_BUFF_SIZE]Vertex,
	active_vbo:           u32,

	//NOTE: Misc 
	time:                 f64,
	mouse_pos:            [2]f32,
	indices:              []u32,


	//Input
	key_input_queue:      [u32(Key.COUNT)]Input_Action,
	mouse_input_queue:    [u32(Mouse_Button.COUNT)]Input_Action,
	mouse_clicked:        bool,

	//Textures
	curr_texture_hndl:    u32,
	loaded_texture:       Ducc_Texture,
	default_font:         Ducc_Font,

	//NOTE: This should be removed
	camera:               Camera,
}

Ducc_Texture :: struct {
	hndl:   u32,
	data:   [^]byte,
	height: i32,
	width:  i32,
}

Ducc_Texture_Atlas :: struct {
	hndl:        u32,
	data:        [^]byte,
	height:      i32,
	width:       i32,
	rows:        i32,
	cols:        i32,
	sprite_size: i32,
}

Ducc_Font :: struct {
	hndl:        u32,
	data:        [^]byte,
	height:      i32,
	width:       i32,
	rows:        i32,
	cols:        i32,
	sprite_size: i32,
	offset:      i32,
}

//TODO: This probably shouldn't be a static global, maybe make it a pointer you can pass around when needed on init?
// That being said the consumer probably shouldn't care too much about this context it's more for the platform layer and/or renderer to use to do stuff
ctx: Context
