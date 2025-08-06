package lib

/*
CONSIDER THIS THE RENDER LAYER
	- Should be abstracted away from the platform layer (i.e try to avoid using glfw.gl_set_proc_address)
	- Intended to draw stuff (shapes, text, and textures mainly)
	- Don't want to add too many app specific things here
*/

import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:fmt"
Color :: distinct [4]int
//NOTE: These are ripped straight from Raylib could probably do something else if we wanted
LIGHTGRAY  :: Color{ 200, 200, 200, 255 }   // Light Gray
GRAY       :: Color{ 130, 130, 130, 255 }   // Gray
DARKGRAY   :: Color{ 80, 80, 80, 255 }      // Dark Gray
YELLOW     :: Color{ 253, 249, 0, 255 }     // Yellow
GOLD       :: Color{ 255, 203, 0, 255 }     // Gold
ORANGE     :: Color{ 255, 161, 0, 255 }     // Orange
PINK       :: Color{ 255, 109, 194, 255 }   // Pink
RED        :: Color{ 230, 41, 55, 255 }     // Red
MAROON     :: Color{ 190, 33, 55, 255 }     // Maroon
GREEN      :: Color{ 0, 228, 48, 255 }      // Green
LIME       :: Color{ 0, 158, 47, 255 }      // Lime
DARKGREEN  :: Color{ 0, 117, 44, 255 }      // Dark Green
SKYBLUE    :: Color{ 102, 191, 255, 255 }   // Sky Blue
BLUE       :: Color{ 0, 121, 241, 255 }     // Blue
DARKBLUE   :: Color{ 0, 82, 172, 255 }      // Dark Blue
PURPLE     :: Color{ 200, 122, 255, 255 }   // Purple
VIOLET     :: Color{ 135, 60, 190, 255 }    // Violet
DARKPURPLE :: Color{ 112, 31, 126, 255 }    // Dark Purple
BEIGE      :: Color{ 211, 176, 131, 255 }   // Beige
BROWN      :: Color{ 127, 106, 79, 255 }    // Brown
DARKBROWN  :: Color{ 76, 63, 47, 255 }      // Dark Brown

WHITE      :: Color{ 255, 255, 255, 255 }   // White
BLACK      :: Color{ 0, 0, 0, 255 }         // Black
BLANK      :: Color{ 0, 0, 0, 0 }           // Blank (Transparent)
MAGENTA    :: Color{ 255, 0, 255, 255 }     // Magenta

rducc_render_init :: proc() {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address) //required for proc address stuff
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	//Enables alpha transparency
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

//NOTE: This is exactly how raylib does their ClearBackground logic
rducc_render_background_clear :: proc(color: Color) {
	r := f32(color.r)/255.
	g := f32(color.g)/255.
	b := f32(color.b)/255.
	a := f32(color.a)/255.
	gl.ClearColor(r,g,b,a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

rducc_render_box :: proc() {
}
