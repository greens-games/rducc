package src

import rl "vendor:raylib"

//TC Exports
@(export)
api_init :: proc() -> rawptr {
	return init()
}

@(export)
api_update :: proc(game_mem: rawptr) {
	update(cast(^Game_Mem)game_mem)
	draw(cast(^Game_Mem)game_mem)
}

@(export)
api_should_restart :: proc() -> bool {
	return false
}

@(export)
api_should_close:: proc() -> bool {
	return false
}

/* @(export)
api_set_state :: proc(data: rawptr) {
	game_state = cast(^Game_Mem)data
} */

@(export)
api_get_state :: proc() -> uint {
	return size_of(Game_Mem)
}

@(export)
api_close :: proc() {
}

@(export)
api_clean_up :: proc() {
	clean_up()
}
