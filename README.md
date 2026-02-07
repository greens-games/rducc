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

## Demo game
- Side scrolling
    - RPG/Metroid vania
    - Platformer
    - Survival (like terraria/Noita)
- Top down
    - Tactics (Fire emblem)
    - RTS
    - Automation
    - JRPG with overworld + 2D battles
    - Tower defense

- Other
    - VTT
    - Editor

## Some metholodogies to think of
- Write the instructions needed to accomplish task so it run; we can try this more at work too
- If sets of instructions are used more than once; compress to function
- If sets of variables need to be used in more than once place; compress into struct/class
    - I kind of already do this but let's to do it more

## Renderer missing features
- Box outline
- Circle outline
- Use ttf fonts
- Custom shaders
- Camera
- Platform separation (currently we use glfw + opengl which works for Windows and Linux fine enough)
