package debug

import "core:fmt"

debug_print_pixels :: proc(data: []u8, height, width: int) {
	pixel_count := 0
	for b, i in data {
		fmt.printf("%02X", b)
		pixel_count += 1
		if pixel_count % 3 == 0 {
			fmt.printf(" 0x")
			pixel_count = 0
		}
		if i % width == 0 {
			fmt.println()
			fmt.println()
		}
	}
}
