package main

import "core:image"
import "core:image/png"
import "core:image/bmp"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import fs "vendor:fontstash"
import stbi "vendor:stb/image"
import tty "vendor:stb/truetype"

import "debug"
import "rducc"
import "pducc"


/**
Table of Contents:
	CLEANUP
	RENDER
	PHYSICS
	INIT
*/

Game_State :: enum {
	PLAYING,
	MENU,
	PAUSED,
}

Entity :: struct {
	pos:      [2]f32,
	scale:    [2]f32,
	collider: pducc.Collider,
}

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
}


run :: proc() {
	rducc.init(980,620,"RDUCC DEMO")
	curr_rotation: f32 = 0.

	percy_image, percy_image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := rducc.sprite_load(percy_image.pixels.buf[:], percy_image.height, percy_image.width)
	percy_pos := [2]f32{150, 150}
	percy_scale := [2]f32{32, 32}

	game_frame_arena: virtual.Arena 
	arena_err := virtual.arena_init_static(&game_frame_arena)
	assert(arena_err == nil)
	game_frame_arena_allocator := virtual.arena_allocator(&game_frame_arena)

	bullets := make_slice([]Entity, 100, game_frame_arena_allocator)

	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()

	r_group2 := rducc.render_group_create()
	for !rducc.window_close() {
		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := rducc.time_delta_get()

		//TC: INPUT
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) {
			m_collider: pducc.Collider
			m_collider.kind = .RECT
			m_collider.origin = m_pos
			m_collider.scale = [2]f32{10, 10}
			percy_collider: pducc.Collider
			percy_collider.kind = .RECT
			percy_collider.origin = percy_pos
			percy_collider.scale = percy_scale
			if pducc.rect_collision(m_collider, percy_collider) {
				//TODO: This can sometimes stop being detected when moving too fast
				percy_pos += m_pos_change
			}
		}

		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			{
				bullet: Entity
				bullet.pos = [2]f32{percy_pos.x, percy_pos.y + 10}
			}
		}

		if rducc.window_is_key_pressed(.KEY_Q) {
		}

		if rducc.window_is_key_pressed(.KEY_R) {
			rducc.shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")
			rducc.projection_set()
		}

		// TC: PHYSICS
		
		//TC: RENDER
		rducc.background_clear(rducc.GRAY)
		rducc.draw_box({400.0, 500.0}, {64.0, 32.0}, colour = rducc.BLUE)
		rducc.draw_text("Hello", {400.0, 500.0}, 32)
		rducc.draw_circle({120.0, 200.0}, {32.0, 16.0}, colour = rducc.RED)
		rducc.draw_circle(bullet.pos, {16, 16})
		rducc.draw_sprite(percy_texture, percy_pos, percy_scale)
		rducc.commit()

		//TC: CLEANUP
		free_all()
		prev_m_pos = m_pos
	}
}
