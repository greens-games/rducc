package main

import "../src/game"
import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

count := 0


main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

	}

	game.init()
	defer {
		game.clean_up()
		free(game.game_state)
	}
	fmt.println(size_of(game.Game_State))
	for !rl.WindowShouldClose() {
		game.update()
		game.draw()
	}
}
