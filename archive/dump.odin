package rducc

//NOTE: For polygons we need to define the vertices we are doing and adjust scaling based on that I think
renderer_polygon :: proc(pos: [3]f32, scale: [2]f32, rotation: f32 = 0.0, colour := PINK) {
	vertices := [?]f32{0.0, 1.0, 0.0, -0.5, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.0, 0.0}
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	renderer_colour_apply(colour)
	/* renderer_mvp_apply(vert_info, frag_info) */
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.DrawArrays(gl.LINES, 3, 2)
}

renderer_polygon_sides :: proc(
	pos: [3]f32,
	scale: [2]f32,
	sides: i32,
	rotation: f32 = 0.0,
	colour := PINK,
) {
	assert(sides < 20)
	vertices: [20]Vertex
	segments := sides
	two_pi := 2.0 * math.PI

	vertices[0] = {
		pos_coords = {pos.x, pos.y, 0.0},
	}

	for i in 0 ..= segments {
		circ_pos := f32(f64(i) * two_pi / f64(segments))
		vertices[i].pos_coords.x = pos.x + (scale.x * math.cos_f32(circ_pos))
		vertices[i].pos_coords.y = pos.y + (scale.y * math.sin_f32(circ_pos))
		vertices[i].pos_coords.z = 0.0
	}

	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW)
	/* gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices_temp), &vertices_temp, gl.DYNAMIC_DRAW) */
	renderer_colour_apply(colour)
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(segments + 1))
	/* gl.DrawArrays(gl.TRIANGLE_FAN, 0, 5) */
}

renderer_circle_outline_draw :: proc(
	pos: [3]f32,
	radius: [2]f32,
	rotation: f32 = 0.0,
	colour := PINK,
) {
	program_load(Shader_Progams.CIRCLE_OUTLINE)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(vertices_index_box),
		&vertices_index_box,
		gl.DYNAMIC_DRAW,
	)
	renderer_colour_apply(colour)

	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, raw_data(ctx.indices))
	program_load(Shader_Progams.PRIMITIVE)
}

cell_slots :: proc() {
		for row, r in game_ctx.grid {
			for col, c in row {
				if col.occupiers[0] != -1 {
					colour: rducc.Colour
					colour = {255,255,255,125}
					rducc.draw_box({f32(c) * SPRITE_SCALE.x, f32(r) * SPRITE_SCALE.y, 0.0}, SPRITE_SCALE, colour = colour)
				}
			}
		}

		//TC: Assign Grid Cells
		for idx in 0..< game_ctx.entity_count {
			entity := &game_ctx.entities[idx]
			cell_pos := pos_to_cell(entity.pos)
			curr_pos := entity.curr_cell
			col := cell_pos.x
			row := cell_pos.y
			game_ctx.grid[curr_pos.y][curr_pos.x].occupiers[0] = -1
			game_ctx.grid[row][col].occupiers[0] = entity.id
			entity.curr_cell = {col, row}
		}
}


/*
RELATIVE = percentage relative to window size
ABSOLUTTE = x,y as is
*/
Position_Kind :: enum {
	RELATIVE,
	ABSOLUTE,
}
/*
RELATIVE = percentage relative to window size
ABSOLUTTE = x,y as is
*/
widget_button :: proc(text: string, button_pos, button_size, mouse_pos: [2]f32, pos_kind: Position_Kind) -> bool {
	h := hash.ginger16(transmute([]byte)text)
	clicked := false
	_pos := button_pos
	switch pos_kind {
	case .RELATIVE:
		assert(button_pos.x <= 100 && button_pos.y <= 100)
		assert(button_pos.x >= 0 && button_pos.y >= 0)
		_pos.x = f32(rducc.ctx.window_width)  * (button_pos.x * 0.01) - button_size.x
		_pos.y = f32(rducc.ctx.window_height) * (button_pos.y * 0.01) - button_size.y
	case .ABSOLUTE:
	}
	mouse_collider: pducc.Collider 
	mouse_collider = {}
	mouse_collider.scale = {4.0, 4.0}
	mouse_collider.kind = .RECT
	mouse_collider.origin = mouse_pos

	button_collider: pducc.Collider = {}
	button_collider.origin = _pos
	button_collider.scale = button_size
	button_collider.kind = .RECT
	colour := rducc.BLUE

	if pducc.rect_collision(mouse_collider, button_collider) {
		hot_widget = i32(h)
		colour = rducc.GREEN
		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			active_widget = i32(h)
			clicked = true
		}
	}

	rducc.draw_text(rducc.ctx.default_font, text, _pos, 16, rducc.WHITE)
	rducc.draw_box({_pos.x, _pos.y}, button_size, colour = colour)

	return clicked
}
