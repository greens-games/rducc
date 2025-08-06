package lib

/*
CONSIDER THIS THE PLATFORM LAYER
	- Current just sets up the window and checks if it should close it
	- Setup to only be for glfw right now
	- Avoid adding any renderer specific properties or logics

*/

import "base:runtime"
import "core:fmt"
import "core:c"
import "vendor:glfw"

rducc_window_init :: proc(window_width, window_height: i32, name: cstring) {

	//SetUp stuff
	if glfw.Init() != true {
		fmt.println("Failed to init")
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.SetErrorCallback(rducc_error_callback)
	window_handle := glfw.CreateWindow(window_width, window_height, name, nil, nil)
	if window_handle == nil {
		fmt.println("Failed to create window")
	}
	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)

	glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window_handle, rducc_mouse_move_callback)
	glfw.SetMouseButtonCallback(window_handle, rducc_move_button_callback)

	ctx.window_hndl = window_handle
}

rducc_error_callback :: proc "c" (error: c.int, description: cstring) {
	context = runtime.default_context()
	fmt.printfln("ERROR: %v; DESC: %v; VERSIONS: %v", error, description, glfw.GetVersionString())
}

rducc_mouse_move_callback :: proc "c" (window: glfw.WindowHandle, x_pos, y_pos: f64) {
	context = runtime.default_context()
}

rducc_move_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: c.int){
	context = runtime.default_context()
}

/* TODO: add some way to do this that doesn't lock in a render layer specific
rducc_resize_callback :: proc "c" (window: glfw.WindowHandle, width: c.int, height: c.int) {
	gl.Viewport(0, 0, width, height)
} */

rducc_window_close :: proc() -> bool {
	if glfw.GetKey(ctx.window_hndl, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(ctx.window_hndl, true)
	}
	glfw.PollEvents()
	glfw.SwapBuffers(ctx.window_hndl)
	return bool(glfw.WindowShouldClose(ctx.window_hndl))
}
