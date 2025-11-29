package main

import "core:time"
import "rducc"
import "pducc"

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

Game_Context :: struct {
	entities:     [100]Entity,
	entity_count: i32,
	grid:         [ROWS][COLS]Cell,
}

Entity :: struct {
	id:        i32,
	kind:      Entity_Kind,
	pos:       [3]f32,
	curr_cell: [2]u32,
	rotation:  f32,
	scale:     [2]f32,
	collider:  pducc.Collider,
}

Cell :: struct {
	occupiers: [3]i32,
}

SPRITE_SCALE :: [2]f32{32.0, 32.0}
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
	rducc.renderer_init()
	curr_rotation: f32 = 0.

	mouse_entity: Entity
	mouse_entity.scale = {16.0, 16.0}
	mouse_entity.id = 0
	mouse_entity.collider = {}
	mouse_entity.collider.scale = {16.0, 16.0}
	mouse_entity.collider.kind = .RECT
	mouse_entity.collider.radius = 16.0

	random_circle: Entity
	random_circle.scale = {32.0, 32.0}
	random_circle.pos = {100.0, 100.0, 0.0}
	random_circle.collider = {}
	random_circle.collider.scale = {32.0, 32.0}
	random_circle.collider.kind = .RECT
	random_circle.collider.radius = 16.0
	random_circle.collider.origin = {random_circle.pos.x, random_circle.pos.y}

	percy_texture := rducc.renderer_sprite_load("res/scuffed_percy.png")
	player_filled_texture := rducc.renderer_sprite_load("res/player_filled_transparent.png")

	colour := rducc.GREEN

	for !rducc.window_close() {
		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		dt := rducc.time_delta_get()

		//TC: INPUT
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) {
		}
		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_draw = !debug_draw
		}
		if rducc.window_is_key_pressed(.KEY_Q) {
		}

		// TC: PHYSICS
		mouse_entity.pos = {m_pos.x - 8, m_pos.y - 8, 0.0}
		mouse_entity.collider.origin = m_pos.xy

		if pducc.rect_collision(mouse_entity.collider, random_circle.collider) {
			colour = rducc.PINK
		} else {
			colour = rducc.GREEN
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

		//TC: RENDER
		rducc.renderer_background_clear(rducc.GRAY)

		for row, r in game_ctx.grid {
			for col, c in row {
				if col.occupiers[0] != -1 {
					colour: rducc.Colour
					colour = {255,255,255,125}
					rducc.renderer_box({f32(c) * SPRITE_SCALE.x, f32(r) * SPRITE_SCALE.y, 0.0}, SPRITE_SCALE, colour = colour)
				}
			}
		}

		for idx in 0..<game_ctx.entity_count {
			e := game_ctx.entities[idx]
			switch e.kind {
			case .TOKEN:
				/* rducc.renderer_sprite_draw(e.pos, e.scale, e.rotation, rducc.WHITE) */
				rducc.renderer_box(e.pos, e.scale, e.rotation, rducc.BLACK)
			}
		}


		rducc.renderer_box({50.0,50.0,1.0}, {32.0,32.0}, 0.0, rducc.RED)
		rducc.renderer_box_lines({50.0,50.0,1.0}, {32.0,32.0}, 0.0, rducc.GREEN)
		rducc.renderer_circle_shader({100.0,100.0,0.0}, {32.0, 32.0}, 0.0, rducc.BLUE)
		rducc.renderer_circle_shader({m_pos.x - 8, m_pos.y - 8, 0.0}, {16.0, 16.0}, 0.0, colour)
		rducc.renderer_sprite_draw(percy_texture, {150.0,150.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(player_filled_texture, {180.0,350.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(percy_texture, {150.0,370.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(percy_texture, {150.0,290.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(player_filled_texture, {350.0,350.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(player_filled_texture, {460.0,350.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(player_filled_texture, {570.0,350.0,1.0}, {32.0,32.0})
		rducc.renderer_sprite_draw(player_filled_texture, {280.0,350.0,1.0}, {32.0,32.0})
		rducc.renderer_commit()

		//TC: CLEANUP
		//NOTE: This is really bad and should probably not stay, find a better way to free bullets
		free_all()
	}
}

clamp_pos :: proc(pos: [3]f32, velocity: [2]f32) -> [3]f32 {
	_pos := pos
	_pos.x = clamp(_pos.x + velocity.x, 0.0, (COLS - 1.0) * SPRITE_SCALE.x)
	_pos.y = clamp(_pos.y + velocity.y, 0.0, (ROWS - 1.0) * SPRITE_SCALE.y)
	return _pos
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
