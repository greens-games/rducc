package debug

import "core:fmt"
import "base:runtime"
import "core:reflect"
import "core:strings"
import "../rducc"

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

debug_entity_box :: proc(pos: [2]f32, $E: typeid, data: rawptr, colour: rducc.Colour) {
	font_size := 12
	
	box_size := [2]f32{
		500,
		f32(10 * i32(font_size))}

	_pos_x := clamp(pos.x - box_size.x,
		0.0,
		f32(rducc.window_width()))
	rducc.push_box({_pos_x, pos.y - f32(9 * i32(font_size))}, box_size, colour = colour)

	if data != nil {
		info := type_info_of(E)
		more_info := runtime.type_info_core(info)
		casted_data := (^E)(data)^

		sb: strings.Builder
		strings.builder_init_none(&sb, context.temp_allocator)
		field_names := reflect.struct_field_names(E)
		for index in 0..<more_info.variant.(runtime.Type_Info_Struct).field_count {
			field_value := reflect.struct_field_value(casted_data, reflect.struct_field_at(E, int(index)))
			s_name := fmt.tprintf("%v: ", field_names[index])
			s := fmt.tprintf("%v\n", field_value)
			strings.write_string(&sb, s_name)
			strings.write_string(&sb, s)
		}
		rducc.push_text(strings.to_string(sb), {_pos_x, pos.y - f32(font_size)}, f32(font_size))
	}
}
