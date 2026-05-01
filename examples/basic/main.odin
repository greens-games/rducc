package main

import pl "../../plumage"

main :: proc() {
	pl.init(920, 680, "basic_game")
	for !pl.window_close() {
		pl.background_clear(pl.GRAY)
		pl.box_push({10, 10}, {10, 10}, pl.RED)
		pl.commit()
	}

	pl.window_destroy()

}
