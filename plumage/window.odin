package plumage

import "core:math"
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
import gl "vendor:OpenGL"


window_open :: proc(window_width, window_height: i32, name: cstring, full_screen := false) {
	ctx = {}

	//SetUp stuff
	if glfw.Init() != true {
		fmt.println("Failed to init")
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
	glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, true)
	glfw.WindowHint(glfw.RESIZABLE, true)
	glfw.SetErrorCallback(error_callback)
	_window_width := window_width
	_window_height := window_height

	if full_screen {
		primary_monitor := glfw.GetPrimaryMonitor()
		primary_vid_mode := glfw.GetVideoMode(primary_monitor)
		_window_width = primary_vid_mode.width
		_window_height = primary_vid_mode.height
	}

	window_handle := glfw.CreateWindow(_window_width, _window_height, name, nil, nil)

	if window_handle == nil {
		fmt.println("Failed to create window")
	}

	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)

	glfw.SetFramebufferSizeCallback(window_handle, resize_callback)
	glfw.SetCursorPosCallback(window_handle, mouse_move_callback)
	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetScrollCallback(window_handle, mouse_scroll_callback)
	glfw.SetMouseButtonCallback(window_handle, mouse_button_callback)
	ctx.window_width = _window_width
	ctx.window_height = _window_height
	ctx.window_hndl = window_handle

	ctx.time = glfw.GetTime()
}

error_callback :: proc "c" (error: c.int, description: cstring) {
	context = runtime.default_context()
	fmt.printfln("ERROR: %v; DESC: %v; VERSIONS: %v", error, description, glfw.GetVersionString())
}

mouse_move_callback :: proc "c" (window: glfw.WindowHandle, x_pos, y_pos: f64) {
	context = runtime.default_context()
	ctx.mouse_pos = {f32(x_pos), f32(y_pos)}
}

mouse_scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	context = runtime.default_context()
	if ctx.camera != nil {
		c := ctx.camera
		c.zoom = math.max(1.0, ctx.camera.zoom + f32(y_offset) * 0.1)
	}
}

window_height :: proc() -> i32 {
	return ctx.window_height
}

window_width :: proc() -> i32 {
	return ctx.window_width
}

resize_callback :: proc "c" (window: glfw.WindowHandle, width: c.int, height: c.int) {
	context = runtime.default_context()
	//TODO: This should be render agnostic
	ctx.window_height = height
	ctx.window_width = width
	gl.Viewport(0, 0, width, height)
	projection_set()
}

//TODO: Split this up into more granular functions giving user's more control
window_close:: proc() -> bool {
	if glfw.GetKey(ctx.window_hndl, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(ctx.window_hndl, true)
	}

	ctx.key_input_queue = {}
	glfw.PollEvents()
	ctx.mouse_clicked = false
	glfw.SwapBuffers(ctx.window_hndl)
	return bool(glfw.WindowShouldClose(ctx.window_hndl))
}

window_destroy :: proc() {
	glfw.DestroyWindow(ctx.window_hndl)
	glfw.Terminate()
}

window_vsync_set :: proc(should_vsync: bool) {
	glfw.SwapInterval(i32(should_vsync))
}

window_cursor_set :: proc(hide_cursor: bool) {
	state: i32 = hide_cursor ? glfw.CURSOR_HIDDEN : glfw.CURSOR_NORMAL
	glfw.SetInputMode(ctx.window_hndl, glfw.CURSOR, state)
}
