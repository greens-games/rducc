package main

import "../../plumage"
import k2 "../../../../repos/karl2d"

main :: proc() {
	/* karl() */
	mine()
}

mine :: proc() {
	plumage.init(680, 920, "hello")
	base_shader := plumage.shader_load_from_mem(#load("vert.glsl"), #load("frag.glsl"))

	for !plumage.window_close() {
		plumage.background_clear({100, 150, 100, 255})
		plumage.push_box({680/2, 920/2}, {32, 32}, plumage.ORANGE)
		plumage.push_shader(base_shader.id)
		plumage.projection_set()
		plumage.push_box({680/2 + 100, 920/2}, {32, 32}, plumage.WHITE)
		plumage.pop_shader()
		plumage.commit()
	}
}

karl :: proc() {
	k2.init(680, 920, "hello")
	base_shader := k2.load_shader_from_bytes(#load("vert.glsl"), #load("frag.glsl"))

	for k2.update() {
		k2.clear({100, 150, 100, 255})
		k2.draw_rect_vec({680/2, 920/2}, {32, 32}, plumage.ORANGE)
		k2.set_shader(base_shader)
		k2.draw_rect_vec({680/2 + 100, 920/2}, {32, 32}, plumage.WHITE)
		k2.present()
	}

}
