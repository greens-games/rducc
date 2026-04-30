package multi_texture

import pl "../../plumage"

main :: proc() {

	pl.init(680, 920, "multi_texture_game")
	for !pl.window_close() {
		pl.background_clear(pl.BLACK)
		pl.box_push({40, 40}, {32, 32}, pl.RED)
		pl.commit()

	}

}
