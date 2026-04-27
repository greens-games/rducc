package main

import pl "../../plumage"

Circle :: struct {
	pos: [2]f32,
	scale: [2]f32,
}

main :: proc() {
	pl.init(920, 680, "load_test_game")

	circles: [500]Circle
	for &circle in circles {
		circle.pos = {50, 50}
		circle.scale = {32, 32}
	}

	for !pl.window_close() {
		pl.background_clear(pl.GRAY)
		for circle in circles {
			pl.circle_push(circle.pos, circle.scale, pl.RED)
		}
		pl.commit()
	}
}
