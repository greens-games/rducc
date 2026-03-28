package main

import "../../plumage"

main :: proc() {
	plumage.init(920, 680, "Input Test")

	for !plumage.window_close() {
		plumage.process_events()
		plumage.background_clear(plumage.GRAY)
		if plumage.window_is_key_pressed_2(.KEY_A) {
			plumage.push_text("A", {100, 100}, 14)
		}
		if plumage.window_is_key_down_2(.KEY_R) {
			plumage.push_text("R", {200, 100}, 14)
		}

		if plumage.window_is_key_pressed(.KEY_G) {
			plumage.push_text("G", {100, 100}, 14)
		}
		if plumage.window_is_key_down(.KEY_K) {
			plumage.push_text("K", {200, 100}, 14)
		}
		plumage.commit()
	}
}
