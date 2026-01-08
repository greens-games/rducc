## Purpose
- Inital intention is to learn graphics programming by building a basic immediate mode graphics renderer library
- Extend to be a GUI library intended to be used for other desktop applications

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


## Render Groups
- We can go with 1 of the following
    1.
        - Store a pointer to the active render group on CTX
        - Explicitly say render_group_start > call all draws > render_group_end
    2.
        - Have all render calls take a pointer to a group
        - have all groups be a linked list/stack
        - When we commit go through stack and commit each render group

## Some metholodogies to think of
- Write the instructions needed to accomplish task so it run; we can try this more at work too
- If sets of instructions are used more than once; compress to function
- If sets of variables need to be used in more than once place; compress into struct/class
    - I kind of already do this but let's to do it more


## Current tasks
- Use proper ttf fonts or atleast get a transparent font!!!
- Widgets
    - Sort out active and hot widgets
    - Text box widget
- Fill background with texture
- Use arena allocator for default allocator
- Renderer
    - Draw grid
    - Camera

## Other fun stuff
- First understand the existing odin context allocators and what they are doing
- Write own context allocator for an Arena
