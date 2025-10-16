## Purpose
- Inital intention is to learn graphics programming by building a basic immediate mode graphics renderer library
- Extend to be a GUI library intended to be used for other desktop applications


## Current tasks
- Renderer
    - Draw grid
    - Camera
    - Batch rendering
    - Multiple textures (Texture atlas to start?)
- Physics
    - Circle collisions
        - Circle - Circle
        - Circle - Rect
- Game
    - CHange collision detection to just check for things on:
        - Your cell OR
        - Cell you are moving to

## Renderer TODOs
- Do we want to start drawing from middle? we currently draw from bot left (For this we would change the mvp stuff I believe)
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
