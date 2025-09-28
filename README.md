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
    - Set posiitons in grid
    - CHange collision detection to just check for things on:
        - Your cell OR
        - Cell you are moving to

## Renderer TODOs
- Should probably change args for procs to be more specific rather than using Vert_Info and Frag_Info
- Draw Polygons
- Draw text (start with bitmap fonts)
- Draw sprite/texture
- Get hot reloading working
    - Shaders
    - Textures
    - Gameplay code

## Physics
- Polygon collisions
- Collision module is just for detecting if 2 objects are colliding
- We want a module to apply different formulas depending on if 2 objects colliding and some properties about them

## Plans
- Possibly use the renderer to build a game
