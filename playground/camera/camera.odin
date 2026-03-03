package camera

import "../../plumage"

main :: proc() {
	plumage.init(980, 620, "Camera test")

	player_pos := [2]f32{100, 100}
	camera := plumage.camera_init(player_pos, 1)
	for !plumage.window_close() {
		if plumage.window_is_key_down(.KEY_D) {
			camera.target.x += 1
			player_pos.x += 1
		}

		if plumage.window_is_key_down(.KEY_A) {
			camera.target.x -= 1
			player_pos.x -= 1
		}

		if plumage.window_is_key_down(.KEY_S) {
			camera.target.y -= 1
			player_pos.y -= 1
		}

		if plumage.window_is_key_down(.KEY_W) {
			camera.target.y += 1
			player_pos.y += 1
		}
		plumage.camera_begin(camera)
		plumage.background_clear(plumage.GRAY)
		plumage.push_box(player_pos, {32, 32}, plumage.RED)
		plumage.push_box({300, 300}, {32, 32}, plumage.RED)
		plumage.camera_end()
		plumage.commit()
	}
}
