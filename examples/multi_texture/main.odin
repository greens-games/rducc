package multi_texture

import pl "../../plumage"

import "core:image"
import "core:image/png"

main :: proc() {
	pl.init(680, 920, "multi_texture_game")

	percy_image, percy_image_ok := image.load_from_bytes(#load("./scuffed_percy.png"))
	assert(percy_image_ok == nil)
	percy_sprite := pl.sprite_load(percy_image.pixels.buf[:], percy_image.width, percy_image.height)

	for !pl.window_close() {
		pl.background_clear(pl.BLACK)
		pl.sprite_push(percy_sprite, {60, 60}, {32, 32})
		pl.box_push({40, 40}, {32, 32}, pl.RED)
		pl.text_push("Hello", {100, 60}, 16)

		pl.commit()

	}

}
