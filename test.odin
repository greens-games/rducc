package main

import "core:testing"
import "core:fmt"
import "core:strings"

@(test)
flat_array_test :: proc(t: ^testing.T) {
	text := "abc"
	c := strings.to_upper(text, context.temp_allocator)[0]
	rows := 7 
	cols := 7
	flat_texture: [64]i32
	offset_c := c - 32
	idx_y  := offset_c / 8

	adj_cols:int = ((rows + 1) * int(idx_y))
	testing.expect_value(t, adj_cols, 32)
	normalized_offset := (int(offset_c) - adj_cols)
	testing.expect_value(t, normalized_offset, 5)
	idx_x := normalized_offset % (rows + 1)
	testing.expect_value(t, idx_y, 4)
	testing.expect_value(t, idx_x, 5)
}
