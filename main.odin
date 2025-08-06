package main

import "lib"
import "core:fmt"

main :: proc() {
	lib.rducc_window_init(980,620,"RDUCC DEMO")
	lib.rducc_render_init()
	/* lib.rducc_shader_load("res/vert_2d.glsl", "res/frag_primitive.glsl") */
	for !lib.rducc_window_close() {
		lib.rducc_render_background_clear(lib.GRAY)
	}
}
