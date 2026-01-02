package rducc

import gl "vendor:OpenGL"
import "core:mem"

Render_Group :: struct {
	vbo:                  [4]u32,
	num_vertices:         i32,
	box_vertices:         i32,
	circle_vertices:      i32,
	texture_vertices:     i32,
	outline_vertices:     i32,
	curr_texture_hndl:    u32,
}

render_group_init :: proc(group: ^Render_Group) {
	gl.GenBuffers(4, raw_data(&group.vbo))
	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[0])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[1])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[2])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)
}

render_group_commit :: proc(group: ^Render_Group) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[0])
	renderer_vertex_attrib_apply()
	program_load(.PRIMITIVE)
	gl.DrawArrays(gl.TRIANGLES, 0, group.box_vertices)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[1])
	renderer_vertex_attrib_apply()
	program_load(.CIRCLE)
	gl.DrawArrays(gl.TRIANGLES, 0, group.circle_vertices)

	renderer_texture_batch_commit(group.curr_texture_hndl)

	group.box_vertices = 0
	group.circle_vertices = 0
	group.curr_texture_hndl = 0
}

render_group_texture_batch_commit :: proc(handl: u32) {
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO_MULTI[2])
	renderer_vertex_attrib_apply()
	program_load(.TEXTURE)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	gl.DrawArrays(gl.TRIANGLES, 0, ctx.texture_vertices)
	ctx.texture_vertices = 0
}
