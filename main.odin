package main

import "core:math/rand"
import "core:time"
import "core:hash"
import "rducc"
import "pducc"
import "vendor:stb/truetype"
import "vendor:stb/easy_font"

import "core:math/linalg"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"


W_HEIGHT :: 620
W_WIDTH  :: 980

ROWS :: 20
COLS :: 20

Entity_Kind :: enum {
	TOKEN,
}

Widget_Kind :: enum {
	BUTTON,
	TEXT_BOX,
	CHECK_BOX,
}

/*
RELATIVE = percentage relative to window size
ABSOLUTTE = x,y as is
*/
Position_Kind :: enum {
	RELATIVE,
	ABSOLUTE,
}

Game_Context :: struct {
	entities:     [100]Entity,
	entity_count: i32,
	grid:         [ROWS][COLS]Cell,
}

Entity :: struct {
	id:         i32,
	kind:       Entity_Kind,
	texture:    ^rducc.Ducc_Texture,
	pos:        [3]f32,
	curr_cell:  [2]u32,
	rotation:   f32,
	scale:      [2]f32,
	collider:   pducc.Collider,
}

Widget :: struct {
	id:        i32,
	kind:      Widget_Kind,
	pos:       [3]f32,
	rotation:  f32,
	scale:     [2]f32,
	collider:  pducc.Collider,
	active:    bool,
	hot:       bool,
}

hot_widget: i32 = -1
active_widget: i32 = -1

Cell :: struct {
	occupiers: [3]i32,
}

SPRITE_SCALE :: [2]f32{32.0, 32.0}
BASE_SCALE :: [2]f32{16.0, 16.0}
debug_draw := false

//TODO: Add hot reloading
main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	run()
	/* test() */
}

game_context_init :: proc() -> Game_Context{
	ctx: Game_Context
	for row, r in ctx.grid {
		for col, c in ctx.grid {
			ctx.grid[r][c] = {
				{-1, -1, -1}
			}
		}
	}
	return ctx
}

pos_to_cell :: proc(pos: [3]f32) -> [2]u32 {
	return {u32(math.round_f32(pos.x/SPRITE_SCALE.x)), u32(math.round_f32(pos.y/SPRITE_SCALE.y))}
}


run :: proc() {
	game_ctx := game_context_init()
	rducc.window_open(980,620,"RDUCC DEMO")
	r_group1: rducc.Render_Group
	rducc.renderer_init(&r_group1)
	curr_rotation: f32 = 0.

	mouse_entity: Entity
	mouse_entity.scale = {4.0, 4.0}
	mouse_entity.id = 0
	mouse_entity.collider = {}
	mouse_entity.collider.scale = {4.0, 4.0}
	mouse_entity.collider.kind = .RECT
	mouse_entity.collider.radius = 4.0



	//TODO: Decide how we want to handle storing textures
	//Can be:
	//a static array     (entity holds id), 
	//an arena allocator (entity holds pointer to texture), 
	percy_texture := new(rducc.Ducc_Texture)
	percy_texture^ = rducc.renderer_sprite_load("res/scuffed_percy.png")
	player_filled_texture := rducc.renderer_sprite_load("res/player_filled_transparent.png")

	percy_entity: Entity
	percy_entity.texture = percy_texture
	percy_entity.scale = SPRITE_SCALE
	percy_entity.pos = {150.0, 150.0, 1.0}
	percy_entity.id = 0
	percy_entity.collider = {}
	percy_entity.collider.scale = {4.0, 4.0}
	percy_entity.collider.kind = .RECT
	percy_entity.collider.radius = 4.0

	colour := rducc.GREEN
	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()
	for !rducc.window_close() {
		//TC: INIT
		active_widget = -1
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := rducc.time_delta_get()

		//TC: INPUT
		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			fmt.println("M_POS_CHANGE: ", m_pos_change)
		}
		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_draw = !debug_draw
		}
		if rducc.window_is_key_pressed(.KEY_Q) {
		}

		// TC: PHYSICS
		mouse_entity.pos = {m_pos.x - 2, m_pos.y - 2, 0.0}
		mouse_entity.collider.origin = {m_pos.x - 2, m_pos.y - 2}
		
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

		//TC: RENDER
		rducc.renderer_background_clear(rducc.GRAY)
		if widget_button("Hello", {50, 50}, {64,32}, m_pos, .RELATIVE) {
			fmt.println("Activated button")
		}

		widget_token(&percy_entity, m_pos, m_pos_change, .ABSOLUTE)

		for row, r in game_ctx.grid {
			for col, c in row {
				if col.occupiers[0] != -1 {
					colour: rducc.Colour
					colour = {255,255,255,125}
					rducc.renderer_box_draw({f32(c) * SPRITE_SCALE.x, f32(r) * SPRITE_SCALE.y, 0.0}, SPRITE_SCALE, colour = colour)
				}
			}
		}

		for idx in 0..<game_ctx.entity_count {
			e := game_ctx.entities[idx]
			switch e.kind {
			case .TOKEN:
				/* rducc.renderer_sprite_draw(e.pos, e.scale, e.rotation, rducc.WHITE) */
				rducc.renderer_box_draw({e.pos.x, e.pos.y, 10.0}, e.scale, e.rotation, rducc.BLACK)
			}
		}


		rducc.renderer_circle_draw({m_pos.x, m_pos.y, 0.0}, {4.0,4.0}, colour = rducc.RED)
		rducc.renderer_text_draw(rducc.ctx.default_font, "Hello World!", {600.0, 500.0}, 16)
		rducc.renderer_commit()

		//TC: CLEANUP
		//NOTE: This is really bad and should probably not stay, find a better way to free bullets
		free_all()
		prev_m_pos = m_pos
	}
}

clamp_pos :: proc(pos: [3]f32, velocity: [2]f32) -> [3]f32 {
	_pos := pos
	_pos.x = clamp(_pos.x + velocity.x, 0.0, (COLS - 1.0) * SPRITE_SCALE.x)
	_pos.y = clamp(_pos.y + velocity.y, 0.0, (ROWS - 1.0) * SPRITE_SCALE.y)
	return _pos
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

	rducc.renderer_text_draw(rducc.ctx.default_font, text, _pos, 16, rducc.WHITE)
	rducc.renderer_box_draw({_pos.x, _pos.y, 0.0}, button_size, colour = colour)

	return clicked
}

widget_text_box :: proc(id: int, pos: [3]f32, box_size, mouse_pos: [2]f32) {
}

widget_token :: proc(entity:^Entity,
					 mouse_pos: [2]f32,
					 m_pos_change: [2]f32,
					 pos_kind: Position_Kind) -> bool {
	clicked := false
	_pos := entity.pos
	switch pos_kind {
	case .RELATIVE:
		_pos.x = f32(rducc.ctx.window_width)  * (entity.pos.x * 0.01) - entity.scale.x
		_pos.y = f32(rducc.ctx.window_height) * (entity.pos.y * 0.01) - entity.scale.y
	case .ABSOLUTE:
	}
	mouse_collider: pducc.Collider 
	mouse_collider = {}
	mouse_collider.scale = {8.0, 8.0}
	mouse_collider.kind = .RECT
	mouse_collider.origin = rducc.window_mouse_pos()

	button_collider: pducc.Collider = {}
	button_collider.origin = _pos.xy
	button_collider.scale = entity.scale
	button_collider.kind = .RECT
	colour := rducc.BLUE

	if pducc.rect_collision(mouse_collider, button_collider) {
		colour = rducc.GREEN
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) {
			clicked = true
			m_pos := rducc.window_mouse_pos()
			diff_pos := m_pos - entity.pos.xy
			entity.pos += {m_pos_change.x, m_pos_change.y, 0.0}
		}
	}

	rducc.renderer_sprite_draw(entity.texture^, entity.pos, entity.scale)

	return clicked
}


debug_profile :: proc(a: rawptr, msg: string) {
	start := time.now()
	_a := cast(proc()) a
	_a()
	end := time.now()
	fmt.printfln("Time taken to draw box: %d", (end._nsec - start._nsec))
}

test :: proc() {
	fmt.printfln("%d", size_of(rducc.Vertex))
}
