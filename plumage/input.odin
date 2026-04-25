package plumage

import "vendor:glfw"
import "base:runtime"

when 1 == 1 {
	Key :: enum {
		SPACE         = 32,
		APOSTROPHE    = 39,
		COMMA         = 44,
		MINUS         = 45,
		PERIOD        = 46,
		SLASH         = 47,
		SEMICOLON     = 59,
		EQUAL         = 61,
		LEFT_BRACKET  = 91,
		BACKSLASH     = 92,
		RIGHT_BRACKET = 93,
		GRAVE_ACCENT  = 96, // `
		WORLD_1       = 16,
		WORLD_2       = 16,
		ZERO		  = 48,
		ONE			  = 49,
		TWO			  = 50,
		THREE		  = 51,
		FOUR		  = 52,
		FIVE		  = 53,
		SIX			  = 54,
		SEVEN		  = 55,
		EIGHT		  = 56,
		NINE		  = 57,
		A			  = 65,
		B			  = 66,
		C			  = 67,
		D			  = 68,
		E			  = 69,
		F			  = 70,
		G			  = 71,
		H			  = 72,
		I			  = 73,
		J			  = 74,
		K			  = 75,
		L			  = 76,
		M			  = 77,
		N			  = 78,
		O			  = 79,
		P			  = 80,
		Q			  = 81,
		R			  = 82,
		S			  = 83,
		T			  = 84,
		U			  = 85,
		V			  = 86,
		W			  = 87,
		X			  = 88,
		Y			  = 89,
		Z			  = 90,
		ESCAPE        = 256,
		ENTER         = 257,
		TAB           = 258,
		BACKSPACE     = 259,
		INSERT        = 260,
		DELETE        = 261,
		RIGHT         = 262,
		LEFT          = 263,
		DOWN          = 264,
		UP            = 265,
		PAGE_UP       = 266,
		PAGE_DOWN     = 267,
		HOME          = 268,
		END           = 269,
		CAPS_LOCK     = 280,
		SCROLL_LOCK   = 281,
		NUM_LOCK      = 282,
		PRINT_SCREEN  = 283,
		pause         = 284,
		F1			  = 290,
		F2			  = 291,
		F3			  = 292,
		F4			  = 293,
		F5			  = 294,
		F6			  = 295,
		F7			  = 296,
		F8			  = 297,
		F9			  = 298,
		F10			  = 299,
		F11			  = 300,
		F12			  = 301,
		F13			  = 302,
		F14			  = 303,
		F15			  = 304,
		F16			  = 305,
		F17			  = 306,
		F18			  = 307,
		F19			  = 308,
		F20			  = 309,
		F21			  = 310,
		F22			  = 311,
		F23			  = 312,
		F24			  = 313,
		F25			  = 314,
		KP_0		  = 320,
		KP_1		  = 321,
		KP_2		  = 322,
		KP_3		  = 323,
		KP_4		  = 324,
		KP_5		  = 325,
		KP_6		  = 326,
		KP_7		  = 327,
		KP_8		  = 328,
		KP_9		  = 329,
		KP_DECIMAL    = 330,
		KP_DIVIDE     = 331,
		KP_MULTIPLY   = 332,
		KP_SUBTRACT   = 333,
		KP_ADD        = 334,
		KP_ENTER      = 335,
		KP_EQUAL      = 336,
		LEFT_SHIFT    = 340,
		LEFT_CONTROL  = 341,
		LEFT_ALT      = 342,
		LEFT_SUPER    = 343,
		RIGHT_SHIFT   = 344,
		RIGHT_CONTROL = 345,
		RIGHT_ALT     = 346,
		RIGHT_SUPER   = 347,
		MENU          = 348,
		COUNT             = 349,
	}
}

Mouse_Button :: enum {
	LEFT   = 0,
	RIGHT  = 1,
	MIDDLE = 2,
	COUNT
}

Input_Kind :: enum u8 {
	UP,
	DOWN,
	REPEAT,
}

Input_Action :: struct {
	pressed:    bool,
	held:       bool,
	prev_state: Input_Kind,
	curr_state: Input_Kind,
}

//TODO: WE NEED A PRESSED FUNCTION ALL THESE ARE CURRENTLY DOWN MEANING 1 PRESS IS MULTIPLE USES
window_process_input :: proc() {
	window_hndl := ctx.window_hndl
}

//TODO: we can maybe spin up a thread for reading input, which can write to a queue of key events on the ctx
//That only queues the most recent key we are wanting to get a specific key
window_is_key_down :: proc(key: Key) -> bool {
	return Input_Kind(glfw.GetKey(ctx.window_hndl, i32(key))) == .DOWN
}

//TODO: This consumes the key meaning we can't have 2 "is_key_pressed" for the same key in different spots
window_is_key_pressed :: proc(key: Key) -> bool {
	key_state := ctx.key_input_queue[key]
	//NOTE: This only accounts for DOWN > UP may want to deal with REPEAT > UP if our holding a button
	/* if key_state.curr_state == .DOWN && key_state.prev_state == .UP {
		 ctx.key_input_queue[key].prev_state = .DOWN
		return true
	}
	return false */
	return ctx.key_input_queue[key].pressed
	/* return ctx.key_input_queue[key].pressed */
}

window_is_mouse_button_down :: proc(mouse_button: Mouse_Button) -> bool {
	return glfw.GetMouseButton(ctx.window_hndl, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS
}

window_is_mouse_button_pressed :: proc(mouse_button: Mouse_Button) -> bool {
	mouse_button_state := ctx.mouse_input_queue[mouse_button]
	//NOTE: This only accounts for DOWN > UP may want to deal with REPEAT > UP if our holding a button
	if mouse_button_state.curr_state == .DOWN && mouse_button_state.prev_state == .UP {
		 ctx.mouse_input_queue[mouse_button].prev_state = .DOWN
		ctx.mouse_clicked = true
	}
	return ctx.mouse_clicked
}

window_mouse_pos :: proc() -> [2]f32{
	return ctx.mouse_pos
}

mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32){
	context = runtime.default_context()
	ctx.mouse_input_queue[button].prev_state = ctx.mouse_input_queue[button].curr_state
	ctx.mouse_input_queue[button].curr_state = Input_Kind(action)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	/* if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
		glfw.SetWindowShouldClose(ctx.window_hndl, true)
	} */
	context = runtime.default_context()
	/* fmt.println("KEY: ", key)
	fmt.println("SCANECODE: ", scancode)
	fmt.println("ACTION: ", action)
	fmt.println("MODS: ", mods) */
	ctx.key_input_queue[key].prev_state = ctx.key_input_queue[key].curr_state
	ctx.key_input_queue[key].curr_state = Input_Kind(action)

	ctx.key_input_queue[key].pressed = Input_Kind(action) == .DOWN && !(Input_Kind(action) == .REPEAT)
	ctx.key_input_queue[key].held = Input_Kind(action) == .DOWN || Input_Kind(action) == .REPEAT
}

process_events :: proc() {
	ctx.curr_events = {}
	for &key, index in ctx.curr_events{
		if (index < 32) {
			continue
		}
		action := glfw.GetKey(ctx.window_hndl, i32(index))
		state := Input_Kind(action)
		prev_state := ctx.prev_events[index]
		key.pressed = state == .DOWN && (!prev_state.pressed || !prev_state.held)
		key.held = state == .DOWN && (prev_state.pressed || prev_state.held)
	}
	ctx.prev_events = ctx.curr_events
}
