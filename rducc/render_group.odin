package rducc

import gl "vendor:OpenGL"
import "core:mem"

Render_Group :: struct {
	vbo:                  [4]u32, //Could be dynamic
	num_vertices:         i32,
	box_vertices:         i32,
	circle_vertices:      i32,
	texture_vertices:     i32,
	outline_vertices:     i32,
	curr_texture_hndl:    u32,
}

render_group_create :: proc() -> Render_Group {
	group: Render_Group
	gl.GenBuffers(4, raw_data(&group.vbo))
	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.RECT])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.CIRCLE])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.TEXTURE])
	gl.BufferData(gl.ARRAY_BUFFER, mem.Kilobyte * 64, nil, gl.DYNAMIC_DRAW)
	return group
}

render_group_destroy :: proc(group: ^Render_Group) {
	gl.DeleteBuffers(gl.ARRAY_BUFFER, raw_data(group.vbo[:]))
}

render_group_commit :: proc(group: ^Render_Group) {
	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.RECT])
	vertex_attrib_apply()
	program_load(.PRIMITIVE)
	gl.DrawArrays(gl.TRIANGLES, 0, group.box_vertices)

	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.CIRCLE])
	vertex_attrib_apply()
	program_load(.CIRCLE)
	gl.DrawArrays(gl.TRIANGLES, 0, group.circle_vertices)

	render_group_texture_batch_commit(group)

	group.box_vertices = 0
	group.circle_vertices = 0
	group.curr_texture_hndl = 0
}

render_group_start :: proc(group: ^Render_Group) {
	ctx.active_render_group = group
}

render_group_finish :: proc() {
	render_group_commit(ctx.active_render_group)
	ctx.active_render_group = nil
}


render_group_texture_batch_commit :: proc(group: ^Render_Group) {
	gl.BindBuffer(gl.ARRAY_BUFFER, group.vbo[Render_Buffer.TEXTURE])
	vertex_attrib_apply()
	program_load(.TEXTURE)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	gl.DrawArrays(gl.TRIANGLES, 0, group.texture_vertices)
	group.texture_vertices = 0
}
