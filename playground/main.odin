package playground

import "core:fmt"
import "core:image"
import "core:image/bmp"
import stbi "vendor:stb/image"
import "../rducc"
import "../debug"
import "core:os/os2"
main :: proc() {
	
	font_image, font_image_ok := image.load_from_bytes(#load("../res/Font3.bmp"))
	assert(font_image_ok == nil)
	debug.debug_print_pixels(font_image.pixels.buf[:], int(font_image.height), int(font_image.width))

	/* rducc.ctx.default_font = rducc.font_load(font_image.pixels.buf[:], font_image.height, font_image.width, 32, 32) */

	width, height, channels: i32
	data := stbi.load("res/Font3.bmp", &width, &height, &channels, 4)
	/* debug.debug_print_pixels(data[:height * width], int(height), int(width)) */
}
