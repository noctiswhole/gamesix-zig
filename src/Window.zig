const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Self = @This();
screen: *c.SDL_Window,
context: c.SDL_GLContext,
renderer: *c.SDL_Renderer,
shouldQuit: bool = false,

pub fn createWindow() !Self {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_ES);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 1);
    _ = c.SDL_GL_SetSwapInterval(0);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 24);
    const screen = c.SDL_CreateWindow("My Game Window", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 640, 480, c.SDL_WINDOW_OPENGL) orelse
    {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    const renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_TARGETTEXTURE) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    const context = c.SDL_GL_CreateContext(screen);

    return .{
        .screen = screen,
        .context = context,
        .renderer = renderer
    };
}

pub fn handleInput(self: *Self) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_QUIT => {
                self.shouldQuit = true;
            },
            else => {},
        }
    }
}

pub fn draw(self: Self) void {
    c.SDL_GL_SwapWindow(self.screen);
    c.SDL_Delay(17);
}

pub fn destroyWindow(self: Self) void {
    c.SDL_Quit();
    c.SDL_DestroyWindow(self.screen);
    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_GL_DeleteContext(self.context);
}
