package main

import "core:image"
import "core:image/png"
import "core:image/bmp"
import fs "vendor:fontstash"
import stbi "vendor:stb/image"
import tty "vendor:stb/truetype"
import "debug"

import "core:time"
import "core:hash"
import "rducc"
import "pducc"

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

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
	rducc.window_open(980,620,"RDUCC DEMO")
	rducc.init()
	r_group1 := rducc.render_group_create()
	curr_rotation: f32 = 0.

	percy_image, percy_image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := rducc.sprite_load(percy_image.pixels.buf[:], percy_image.height, percy_image.width)


	//TODO:This does not load the generated font correctly (maybe see karl2d for ttf loading)
	font_image, font_image_ok := image.load_from_bytes(#load("res/Font3.bmp"))
	assert(font_image_ok == nil)
	my_font := rducc.sprite_atlas_load(font_image.pixels.buf[:], font_image.height, font_image.width, 32)


	//TODO: This needs to be moved to renderer init
	width, height, channels: i32
	stbi.set_flip_vertically_on_load(1)
	data := stbi.load("res/Font3.bmp", &width, &height, &channels, 4)
	for idx := 0; idx < int(4*(width *height)); idx += 4 {
		if data[idx] == 0 {
			data[idx + 3] = 0
		}
	}
	my_font2 := rducc.font_load(data[:width * height], int(height), int(width), 32, 32)
	rducc.ctx.default_font = rducc.font_load(data[:width * height], int(height), int(width), 32, 32)

	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()

	r_group2 := rducc.render_group_create()
	for !rducc.window_close() {
		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := rducc.time_delta_get()

		//TC: INPUT
		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			fmt.println("M_POS_CHANGE: ", m_pos_change)
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
		rducc.draw_circle({120.0, 200.0}, {32.0, 16.0}, colour = rducc.RED)
		rducc.draw_text(my_font2, "Hello", {400.0, 500.0}, 32)
		rducc.draw_sprite(percy_texture, {150, 150}, {32, 32})
		rducc.commit()

		//TC: CLEANUP
		free_all()
		prev_m_pos = m_pos
	}
}
