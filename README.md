## Purpose
- Inital intention is to learn graphics programming by building a basic immediate mode graphics renderer library
- Extend to be a GUI library intended to be used for other desktop applications

## Today
- start more game stuff for now?

## Priorities
- Textures
    - Textures have artifacting from the ones around them
    - Textures seem to also have a ~1-2 pixel gap when placed?
- Custom shaders (Needed for lighting and stuff)
    - Mostly working, main issue is trying to get default drawing procs to allow for custom vertex attributes 
    - works for uniforms BUT you need to make sure you use texture + colour + pos in you shader output somewhere
- fix input somehow
    - this may need to be done in game code we'll see
    - Needs to handle mods (shift, ctrl, etc..)
    - Needs to be able to handle multiple pressed checks for same key

## Notes
- Don't shy away from dynamic arrays as much
    - We can use these maybe avoid doing allocations to them every frame at runtime
    - perfectly fine for a setup of a dynamic length array
    - can still use arena allocator for it
- The way we are doing batch rendering may be entirely wrong/slow
    - It's quite possible it's just better to do 1 large buffer
    - Get all the data on the cpu with each call
    - pass it all to the buffer at the end
    - This would require using 1 shader by default
    - We can allow for more shaders from the user but this would do another draw call
    - You essentially attach all the render information to some ShaderProgram information

## Some metholodogies to think of
- Write the instructions needed to accomplish task so it run; we can try this more at work too
- If sets of instructions are used more than once; compress to function
- If sets of variables need to be used in more than once place; compress into struct/class
    - I kind of already do this but let's to do it more

## Platform Layer
- X11 window
    - Process events (input.odin)
    - setProcAddress (see Karl2d?) used in renderer
    - time.odin
    - window.odin
    - context.odin holds a window handle

## Software Renderer
- Not sure where to start but something I would love to try


## Renderer missing features
- Optional Z-Indexing
- Use ttf fonts
- Custom shaders
- Platform separation (currently we use glfw + opengl which works for Windows and Linux fine enough)
- Basic 3D stuff (don't need complex meshes)
