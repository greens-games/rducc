package main

import "../../plumage"

import "core:image"
import "core:image/png"

_ :: png

main :: proc() {
	plumage.init(680, 920, "Text example")
	my_font_image, my_font_ok := image.load_from_bytes(#load("./font2bitmap.png"))
	my_font := plumage.font_load(my_font_image.pixels.buf[:], my_font_image.width, my_font_image.height, 32, 30)
	for !plumage.window_close() {
		plumage.background_clear(plumage.BLACK)
		plumage.push_rune('4', {680/2, 920/2}, 14)
		plumage.push_rune_2('4', {680/2 + 32, 920/2}, 14)
		plumage.commit()
	}
}
