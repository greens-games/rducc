package main

import "../../plumage"
import k2 "../../../../repos/karl2d"

Custom_Vert :: struct {
	pos: [3]f32
}

main :: proc() {
	/* karl() */
	mine()
}

mine :: proc() {
	plumage.init(680, 920, "hello")
	base_shader := plumage.shader_load_from_mem(#load("vert.glsl"), #load("frag.glsl"))
    mainColour := plumage.Colour{130, 0, 0, 100}
	for !plumage.window_close() {
		plumage.background_clear({100, 150, 100, 255})
		plumage.push_box({680/2, 920/2}, {32, 32}, plumage.ORANGE)
		plumage.push_shader(base_shader.id)
		plumage.projection_set()
		t := f32(plumage.time_get())
		plumage.shader_uniform_value_set("time", .F32, &t)
		plumage.push_box({0, 0}, {680, 920}, plumage.BLACK)
		plumage.pop_shader()
		plumage.commit()
	}
}

