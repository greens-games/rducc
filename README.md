## Purpose
- Inital intention is to learn graphics programming by building a basic immediate mode graphics renderer library
- Extend to be a GUI library intended to be used for other desktop applications


## Today's tasks
- Box outline batching
- Circle outline batching
- Drag and drop

## Current tasks
- Renderer
    - Draw grid
    - Camera
    - Batch rendering
    - Multiple textures
        - Texture Atlas
        - Multiple texture units with current texture logic
        - Texture2D Arrays
        - Bindless Textures
- Physics
    - Circle collisions
        - Circle - Circle
        - Circle - Rect
- Game
    - CHange collision detection to just check for things on:
        - Your cell OR
        - Cell you are moving to

## Renderer TODOs
- If gpu buffer is going to be full, commit a draw now then start filling again
- Do we want to start drawing from middle? we currently draw from bot left (For this we would change the mvp stuff I believe)
- Either bring back order based rendering OR fix z-indexing
- Draw Polygons
- Draw text (start with bitmap fonts)
- Get hot reloading working
    - Shaders
    - Textures
- Other APIs (Implement the same OpenGL stuff in these)
    - Vulkan
    - DirectX 11
    - DirectX 12
    - CPU rendering (Software rendering)

## Physics
- Polygon collisions
- Collision module is just for detecting if 2 objects are colliding
- We want a module to apply different formulas depending on if 2 objects colliding and some properties about them

## Plans
- Possibly use the renderer to build a game

## Other fun stuff
- First understand the existing odin context allocators and what they are doing
- Write own context allocator for an Arena
