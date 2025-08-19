package rducc

import "base:runtime"
/*
CONSIDER THIS THE renderer LAYER
	- Should be abstracted away from the platform layer (i.e try to avoid using glfw.gl_set_proc_address)
	- Intended to draw stuff (shapes, text, and textures mainly)
	- Don't want to add too many app specific things here
*/

import "vendor:glfw"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
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

vertices_index_box := [?]f32 {
	1.0, 1.0, 0.0,
	1.0, -1.0, 0.0,
	-1.0, -1.0, 0.0,
	-1.0, 1.0, 0.0,
}


Vert_Info :: struct {
	pos:      [2]f32,
	scale:    [2]f32,
	rotation: f32,
}

Frag_Info :: struct {
	colour: Color,
}

EBO, VAO, VBO: u32

renderer_init :: proc() {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address) //required for proc address stuff
	gl.Viewport(0, 0, ctx.window_width, ctx.window_height)
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
	gl.DebugMessageCallback(debug_proc_t, {})
	//Can add filters here
	gl.DebugMessageControl(gl.DEBUG_SOURCE_API, gl.DEBUG_TYPE_ERROR, gl.DEBUG_SEVERITY_HIGH, 0, nil, gl.TRUE)
	/* gl.DebugMessageControl(gl.DEBUG_SOURCE_API, gl.DEBUG_TYPE_ERROR, gl.DEBUG_SEVERITY_MEDIUM, 0, nil, gl.TRUE) */

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	ctx.indices = make_slice([]u32, 6)
	ctx.indices[0] = 0
	ctx.indices[1] = 1
	ctx.indices[2] = 3
	ctx.indices[3] = 1
	ctx.indices[4] = 2
	ctx.indices[5] = 3

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(ctx.indices) * size_of(ctx.indices[0]), raw_data(ctx.indices), gl.STATIC_DRAW)
	/* gl.BindBuffer(gl.ARRAY_BUFFER, 0) */
	//NOTE: In the OpenGL and Odin examples they bind VertexArray first but for us we need to bind last unsure why
	gl.BindVertexArray(VAO)
}

debug_proc_t :: proc "c" (source: u32, type: u32, id: u32, severity: u32, length: i32, message: cstring, userParam: rawptr) {
	context = runtime.default_context()
	/* switch source {
        case gl.DEBUG_SOURCE_API:             fmt.println("Source: API")
        case gl.DEBUG_SOURCE_WINDOW_SYSTEM:   fmt.println("Source: Window System")
        case gl.DEBUG_SOURCE_SHADER_COMPILER: fmt.println("Source: Shader Compiler")
        case gl.DEBUG_SOURCE_THIRD_PARTY:     fmt.println("Source: Third Party")
        case gl.DEBUG_SOURCE_APPLICATION:     fmt.println("Source: Application")
        case gl.DEBUG_SOURCE_OTHER:           fmt.println("Source: Other")
    } */

    switch (type) {
        case gl.DEBUG_TYPE_ERROR:
			fmt.println("Type: Error")
			fmt.println("MESSAGE: ", message)
        /* case gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR: fmt.println("Type: Deprecated Behaviour")
        case gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR:  fmt.println("Type: Undefined Behaviour")
        case gl.DEBUG_TYPE_PORTABILITY:         fmt.println("Type: Portability")
        case gl.DEBUG_TYPE_PERFORMANCE:         fmt.println("Type: Performance")
        case gl.DEBUG_TYPE_MARKER:              fmt.println("Type: Marker")
        case gl.DEBUG_TYPE_PUSH_GROUP:          fmt.println("Type: Push Group")
        case gl.DEBUG_TYPE_POP_GROUP:           fmt.println("Type: Pop Group")
        case gl.DEBUG_TYPE_OTHER:               fmt.println("Type: Other") */
    }
    /* switch (severity) {
        case gl.DEBUG_SEVERITY_HIGH:         fmt.println("Severity: high")
        case gl.DEBUG_SEVERITY_MEDIUM:       fmt.println("Severity: medium")
        case gl.DEBUG_SEVERITY_LOW:          fmt.println("Severity: low")
        case gl.DEBUG_SEVERITY_NOTIFICATION: fmt.println("Severity: notification")
    } */

}


//NOTE: This is exactly how raylib does their ClearBackground logic
renderer_background_clear :: proc(color: Color) {
	r := f32(color.r)/255.
	g := f32(color.g)/255.
	b := f32(color.b)/255.
	a := f32(color.a)/255.
	gl.ClearColor(r,g,b,a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

renderer_pixel :: proc(vert_info: Vert_Info, frag_info: Frag_Info) {
	vertices := [?]f32 {
		-1.,-1.,0.
	}
	indices := [?]f32 {
		0
	}
	/* gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32), &indices, gl.STATIC_DRAW) */
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	renderer_mvp_apply(vert_info, frag_info)
	gl.DrawArrays(gl.POINTS, 0, len(vertices))
	/* gl.DrawElements(gl.TRIANGLES, 1, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
}

renderer_box :: proc(vert_info: Vert_Info, frag_info: Frag_Info) {
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices_index_box), &vertices_index_box, gl.STATIC_DRAW)
	renderer_mvp_apply(vert_info, frag_info)
	//NOTE: We may want gather all data and do a single draw call at the end but for now we will draw each time
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, raw_data(ctx.indices))
}

renderer_box_lines :: proc(vert_info: Vert_Info, frag_info: Frag_Info) {
	//TODO: This could be indices if we can figure out how to not get the errors?
	vertices := [?]f32 {
		1., 1., 0.,
		1., -1., 0.,
		1., -1., 0.,
		-1., -1., 0.,
		-1., -1., 0.,
		-1., 1., 0.,
		-1., 1., 0.,
		1., 1., 0.,
	}
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	renderer_mvp_apply(vert_info, frag_info)
	//NOTE: We may want gather all data and do a single draw call at the end but for now we will draw each time
	/* gl.DrawElements(gl.LINES, 8, gl.UNSIGNED_INT, raw_data(ctx.indices)) */
	gl.DrawArrays(gl.LINES, 0, 8)
}

renderer_mvp_apply :: proc(vert_info: Vert_Info, frag_info: Frag_Info) {

	projection := glm.mat4Ortho3d(0.0, f32(ctx.window_width), 0.0, f32(ctx.window_height), -1.0, 1.0)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["projection"].location,1,false,&projection[0,0])

	adjusted_scale := [3]f32{vert_info.scale.x/2., vert_info.scale.y/2., 0.}
	i := glm.identity(glm.mat4)
	t := glm.mat4Translate({vert_info.pos.x + adjusted_scale.x,vert_info.pos.y + adjusted_scale.y, 0.})
	s := glm.mat4Scale({vert_info.scale.x/2.,vert_info.scale.y/2.,1.0})
	rot := glm.mat4Rotate({0.0,0.0,1.0}, glm.radians(vert_info.rotation))
	i *= t
	i *= rot
	i *= s
	gl.UniformMatrix4fv(ctx.loaded_uniforms["transform"].location,1,false,&i[0,0])

	//TODO: do colour in separate function
	r := f32(frag_info.colour.r)/255.
	g := f32(frag_info.colour.g)/255.
	b := f32(frag_info.colour.b)/255.
	a := f32(frag_info.colour.a)/255.
	//TODO: Colour can probably be an attribute rather than uniform
	gl.Uniform4f(ctx.loaded_uniforms["colour"].location, r, g, b, a)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

}
