## Purpose
- Inital intention is to learn graphics programming by building a basic immediate mode graphics renderer library
- Extend to be a GUI library intended to be used for other desktop applications


## Priorities
- Textures
    - Why do I need GenerateMipMaps
    - Textures do not shrink and grow and maintain quality (something mipmaps related?)
        - Take a look at raylib, and karl2d's draw_texture_fit it still squishes the image BUT the image is sharper
    - Textures keeping all texture data on the CPU is probably bad we should store that on the GPU using texture arrays or something
        - Bound textures?
    - Textures have artifacting from the ones around them
    - Textures seem to also have a ~1-2 pixel gap when placed?
- Custom shaders (Needed for lighting and stuff)
    - Mostly working, main issue is trying to get default drawing procs to allow for custom vertex attributes 
    - works for uniforms BUT you need to make sure you use texture + colour + pos in you shader output somewhere
    - Needs to be able to handle multiple pressed checks for same key

## Platform Layer
- X11 window
    - Process events (input.odin)
    - setProcAddress (see Karl2d?) used in renderer
    - time.odin
    - window.odin
    - context.odin holds a window handle


## Renderer missing features
- Use ttf fonts
- Platform separation (currently we use glfw + opengl which works for Windows and Linux fine enough)
- Basic 3D stuff (don't need complex meshes)
