package playground

import "core:fmt"
import "core:image"
import "core:image/png"
import stbi "vendor:stb/image"
import tty "vendor:stb/truetype"
import fs "vendor:fontstash"
import gl "vendor:OpenGL"
import "../rducc"
import "../debug"
import "core:os/os2"
import "core:mem"

/**
CURRENTLY TRYING:
	Different ways of working with ttf files
	On hold for now since we can work with BMP just fine
	Options:
		STB TrueType:
			GetCodepointBitmap
			BakeFontBitmap
		Fontstash
		My own implementation
*/

Font_Thing :: struct {
	pixels:     []byte,
	char_array: []tty.bakedchar,
	height:     i32,
	width:      i32,
	offset:     i32,
	hndl:       u32,
}

main :: proc() {
	rducc.window_open(980,620,"RDUCC DEMO")
	rducc.init()

	//// FONT LOADING /////
	/* my_font_data: []u8 = #load("../res/GomePixel-ARJd7.otf") */
	/* my_font_data: []u8 = #load("/usr/share/fonts/truetype/freefont/FreeMono.ttf") */
	my_font_data: []u8 = #load("roboto.ttf")

	//// STB TRUETYPE CODEPOINT BMP /////
	my_font_info: tty.fontinfo
	tty.InitFont(&my_font_info, raw_data(my_font_data), tty.GetFontOffsetForIndex(raw_data(my_font_data), 0)) //This is where we would load the font data and then use that data to render
	w, h, xoff, yoff: i32
	bmp := tty.GetCodepointBitmap(&my_font_info, 16,16, 'H', &w, &h, &xoff, &yoff) //bitmap of a single letter

	ix0, ix1, iy0, iy1: i32
	tty.GetCodepointBitmapBox(&my_font_info, 'H', 16, 16, &ix0, &iy0, &ix1, &iy1)

	output := make_slice([]u8, 1024)
	tty.MakeCodepointBitmap(&my_font_info, raw_data(output), 16, 16, 16, 16, 16, 'H')

	fmt.println("DONE")

	//// FONTSTASH /////
	font_ctx: fs.FontContext
	
	my_font_thing: Font_Thing
	load_font(&font_ctx, &my_font_thing, my_font_data, 512, 512, 32)

	for !rducc.window_close() {
		rducc.background_clear(rducc.RED)
		/* rducc.draw_box({500.0, 40.0}, {32.0,32.0}, colour = rducc.RED) */
		draw_font(my_font_thing, "H", {50.0, 50.0}, 16)
		/* draw_text(&font_ctx, {500.0, 400.0}, 16) */
		rducc.commit()
	}
}

load_font :: proc(font_ctx: ^fs.FontContext, font: ^Font_Thing, data: []u8, height, width, offset: i32) {
	texture_hndl: u32
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.GenTextures(1, &texture_hndl)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture_hndl)

	/// TRUETYPE ////
	font.pixels = make_slice([]byte, width * height)
	font.char_array = make_slice([]tty.bakedchar, 96)
	v := tty.BakeFontBitmap(raw_data(data), 0, f32(offset), raw_data(font.pixels[:]), width, height, offset, 96, raw_data(font.char_array[:]))
	font.hndl = texture_hndl
	font.height = height
	font.width = width
	font.offset = offset

	/// FONTSTASH ////
	/* fs.Init(font_ctx, int(width), int(height), .TOPLEFT)
	fs.AddFontMem(font_ctx, "", data, false)
	font.hndl = texture_hndl
	font.pixels = font_ctx.textureData
	font.width = i32(font_ctx.width)
	font.height = i32(font_ctx.height)
	font.offset = offset */

	/// CODEPOINT BMP
	/* my_font_info: tty.fontinfo
	tty.InitFont(&my_font_info, raw_data(data), tty.GetFontOffsetForIndex(raw_data(data), 0))  */
}

draw_font :: proc(font: Font_Thing, text: string, pos: [2]f32, font_size: f32) {
	if (rducc.ctx.loaded_texture.hndl != 0 && font.hndl != rducc.ctx.loaded_texture.hndl) {
		rducc.commit()
	}

	rducc.ctx.loaded_texture = rducc.Ducc_Texture {
		data   = font.pixels,
		height = font.height,
		width  = font.width,
		hndl   = font.hndl,
	}
	_x := pos.x
	_y := pos.y
	quad: tty.aligned_quad
	tty.GetBakedQuad(&font.char_array[0], 512, 512, 'A' - font.offset, &_x, &_y, &quad, true)
	rducc.push_vertex({quad.x1, quad.y1, 0.0}, {quad.s1, quad.t0}, rducc.WHITE)
	rducc.push_vertex({quad.x1, quad.y0, 0.0}, {quad.s1, quad.t1}, rducc.WHITE)
	rducc.push_vertex({quad.x0, quad.y1, 0.0}, {quad.s0, quad.t0}, rducc.WHITE)
	rducc.push_vertex({quad.x1, quad.y0, 0.0}, {quad.s1, quad.t1}, rducc.WHITE)
	rducc.push_vertex({quad.x0, quad.y0, 0.0}, {quad.s0, quad.t1}, rducc.WHITE)
	rducc.push_vertex({quad.x0, quad.y1, 0.0}, {quad.s0, quad.t0}, rducc.WHITE)
}

draw_text :: proc(font_ctx: ^fs.FontContext, pos: [2]f32, font_size: f32) {
	if (rducc.ctx.loaded_texture.hndl != 0 && 1 != rducc.ctx.loaded_texture.hndl) {
		rducc.commit()
	}

	fs.SetFont(font_ctx, 0)
	fs.SetSize(font_ctx, font_size)
	rducc.ctx.loaded_texture = rducc.Ducc_Texture {
		data   = font_ctx.textureData,
		height = i32(font_ctx.height),
		width  = i32(font_ctx.width),
		hndl   = 5,
	}
	it := fs.TextIterInit(font_ctx, pos.x, pos.y, "H")
	quad: fs.Quad
	for fs.TextIterNext(font_ctx, &it, &quad) {
		rducc.push_vertex({quad.x1, quad.y1, 0.0}, {quad.s1, quad.t0}, rducc.WHITE)
		rducc.push_vertex({quad.x1, quad.y0, 0.0}, {quad.s1, quad.t1}, rducc.WHITE)
		rducc.push_vertex({quad.x0, quad.y1, 0.0}, {quad.s0, quad.t0}, rducc.WHITE)
		rducc.push_vertex({quad.x1, quad.y0, 0.0}, {quad.s1, quad.t1}, rducc.WHITE)
		rducc.push_vertex({quad.x0, quad.y0, 0.0}, {quad.s0, quad.t1}, rducc.WHITE)
		rducc.push_vertex({quad.x0, quad.y1, 0.0}, {quad.s0, quad.t0}, rducc.WHITE)
	}

	/* w, h, xoff, yoff: i32
	bmp := tty.GetCodepointBitmap(font_info, 16,16, 'H', &w, &h, &xoff, &yoff)[:w * h] */
}
