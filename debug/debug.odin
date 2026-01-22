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

debug_entity_box :: proc($E: typeid, data: rawptr) {

	info := type_info_of(E)
	more_info := runtime.type_info_core(info)
	casted_data := (^E)(data)^

	sb: strings.Builder
	strings.builder_init_none(&sb, context.temp_allocator)
	field_names := reflect.struct_field_names(E)
	for idx in 0..<more_info.variant.(runtime.Type_Info_Struct).field_count {
		s_name := fmt.tprintf("%v: ", field_names[idx])
		s := fmt.tprintf("%v\n", reflect.struct_field_value(casted_data, reflect.struct_field_at(E, int(idx))))
		strings.write_string(&sb, s_name)
		strings.write_string(&sb, s)
	}
	fmt.print(strings.to_string(sb))
}
