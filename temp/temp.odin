package temp

API :: struct {
	lib: dynlib.Library,
	init: proc() -> rawptr,
	update: proc(rawptr),
	should_restart: proc() -> bool,
	should_close: proc() -> bool,
	get_state: proc() -> uint,
	/* set_state: proc(data: rawptr), */
	close: proc(),
	clean_up: proc(),
	count: int,
}

api:API
i_timestamp: os.File_Time
i_timestamp_err: os.Error

c_timestamp: os.File_Time
c_timestamp_err: os.Error

when ODIN_OS == .Windows {
	EXT :: "dll"
} else {
	EXT :: "so"
}

copy_dll :: proc() {
	dll, ok := os.read_entire_file(fmt.tprintf("game.{0}", EXT))
	if ok {
		os.write_entire_file(fmt.tprintf("build/game{0}.{1}", api.count, EXT) , dll)
	} else if !ok {
		fmt.println(os.get_last_error())
	}
}

hot_reload_template :: proc() {
	copy_dll()
	i_timestamp, i_timestamp_err = os.last_write_time_by_name(fmt.tprintf("game.{0}", EXT))
	lib_name := fmt.tprintf("build/game{0}.{1}", api.count, EXT)
	fmt.println(lib_name)
	lib, did_load := dynlib.load_library(lib_name)
	api.count += 1
	assert(did_load, dynlib.last_error())

	count, did_init := dynlib.initialize_symbols(&api, lib_name, "api_", "lib")
	assert(did_init, dynlib.last_error())
	og_state := api.init()

		for !api.should_close() {
			if api.should_restart() {
				fmt.println("RESTARTING")
					api.close()
					og_state = api.init()
			} 
			c_timestamp, c_timestamp_err = os.last_write_time_by_name(fmt.tprintf("game.{0}", EXT))
			if c_timestamp != i_timestamp {
				fmt.println("RELOADING")
				time.sleep(2 * time.Second)
				i_timestamp = c_timestamp
				copy_dll()
				lib_name = fmt.tprintf("build/game{0}.{1}", api.count, EXT)
				og_state_size := api.get_state()
				lib, did_load = dynlib.load_library(lib_name)
				api.count += 1

				if did_load {
					count, did_init = dynlib.initialize_symbols(&api, lib_name, "api_", "lib")
				if og_state_size != api.get_state() {
						fmt.println("Restarting game")
						api.close()
						og_state = api.init()
					} else {
					}
					// Re init the game
					assert(did_init, dynlib.last_error())

				} else {
					fmt.println(dynlib.last_error())
				}
				
			} 			
			api.update(og_state)
		}
	api.clean_up()
}
