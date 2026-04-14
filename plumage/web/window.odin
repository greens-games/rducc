package plumage

import "vendor:wasm/WebGL"
import "core:math"
/*
CONSIDER THIS THE PLATFORM LAYER
	- Current just sets up the window and checks if it should close it
	- Setup to only be for glfw right now
	- Avoid adding any renderer specific properties or logics
*/

import "core:sys/wasm/js"


window_open :: proc(window_width, window_height: i32, name: cstring) {
	ctx = {}

	ctx.window_width = window_width
	ctx.window_height = window_height
}

add_canvas_event_listener :: proc(evt: js.Event_Kind, callback: proc(e: js.Event), canvas: string) {
	js.add_event_listener(
		canvas, 
		evt, 
		nil, 
		callback,
		true,
	)
}
