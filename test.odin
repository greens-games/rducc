package main

import "core:testing"
import "core:fmt"
import "core:strings"

@(test)
flat_array_test :: proc(t: ^testing.T) {
	text := "_bc"
	c := strings.to_upper(text, context.temp_allocator)[0]
	flat_texture: [64]i32
	offset_c := c - 32
	testing.expect(t, offset_c == 63, fmt.tprintfln("actual result is %d", offset_c))
}
