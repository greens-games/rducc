package x11

import "core:fmt"
import "vendor:x11/xlib"

open_window :: proc() {
	display := xlib.OpenDisplay(nil)
	window := xlib.CreateSimpleWindow(display, xlib.DefaultRootWindow(display), 0, 0, 920, 680, 0, 0, 0)
	xlib.StoreName(display, window, "Test X11 Window")
	xlib.SelectInput(display, window, {
		.KeyPress,
		.KeyRelease,
		.ButtonPress,
		.ButtonRelease,
		.PointerMotion,
		.StructureNotify,
		.FocusChange,
	})
	xlib.MapWindow(display, window)

	quit := false
	for !quit {
		for xlib.Pending(display) > 0 {
			event: xlib.XEvent
			xlib.NextEvent(display, &event)
			if event.type == .KeyPress {
				fmt.println(event.xkey.keycode)
			}
		}
	}
	xlib.CloseDisplay(display)
}
