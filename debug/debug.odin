package debug

import "core:fmt"
import "base:runtime"
import "core:reflect"
import "core:strings"
import "../plumage"

Debug_Struct :: struct {
}

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

debug_entity_box :: proc(pos: [2]f32, $E: typeid, data: rawptr, colour: plumage.Colour) {
	font_size := 8
	
	box_size := [2]f32{
		232,
		f32(9 * i32(font_size))}

	plumage.push_box(pos, box_size, colour = colour)
	plumage.push_box_lines(pos, box_size, plumage.RED)

	info := type_info_of(E)
	more_info := runtime.type_info_core(info)
	casted_data := (^E)(data)^

	sb: strings.Builder
	strings.builder_init_none(&sb, context.temp_allocator)
	field_names := reflect.struct_field_names(E)
	for name in field_names {
		field := reflect.struct_field_by_name(E, name)
		s_name := fmt.tprintf("%v: ", name)
		#partial switch v in field.type.variant {
		case runtime.Type_Info_Named:
			s := fmt.tprintf("%v\n", v.name)
			strings.write_string(&sb, s_name)
			strings.write_string(&sb, s)
		case:
			field_value := reflect.struct_field_value(casted_data, field)
			s := fmt.tprintf("%v\n", field_value)
			strings.write_string(&sb, s_name)
			strings.write_string(&sb, s)
		}
	}
	plumage.push_text(strings.to_string(sb), {pos.x, pos.y + f32(len(field_names) * font_size)}, f32(font_size))
}
