const assert = @import("std").debug.assert;
const gl = @import("gl");
const std = @import("std");
const Window = @import("Window.zig");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = &gpa.allocator();

const Vertex = struct {
    x: f32,
    y: f32,
    u: f32,
    v: f32,
};



pub fn getProcAddress(p: ?*anyopaque, proc: [:0]const u8) ?*align(4) const anyopaque {
    _ = p;
    return SDL_GL_GetProcAddress(proc);
}
extern fn SDL_GL_GetProcAddress(proc: ?[*:0]const u8) ?*align(4) const anyopaque;

fn compileShader(allocator: *const std.mem.Allocator, vertex_source: [:0]const u8, fragment_source: [:0]const u8) !gl.GLuint {
    const vertex_shader = try compilerShaderPart(allocator, gl.VERTEX_SHADER, vertex_source);
    defer gl.deleteShader(vertex_shader);

    const fragment_shader = try compilerShaderPart(allocator, gl.FRAGMENT_SHADER, fragment_source);
    defer gl.deleteShader(fragment_shader);

    const program = gl.createProgram();
    if (program == 0)
        return error.OpenGlFailure;
    errdefer gl.deleteProgram(program);

    gl.attachShader(program, vertex_shader);
    defer gl.detachShader(program, vertex_shader);

    gl.attachShader(program, fragment_shader);
    defer gl.detachShader(program, fragment_shader);

    gl.linkProgram(program);

    var link_status: gl.GLint = undefined;
    gl.getProgramiv(program, gl.LINK_STATUS, &link_status);

    if (link_status != gl.TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.getProgramiv(program, gl.INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.getProgramInfoLog(program, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{any}", .{info_log});

        return error.InvalidShader;
    }

    return program;
}

fn compilerShaderPart(allocator: *const std.mem.Allocator, shader_type: gl.GLenum, source: [:0]const u8) !gl.GLuint {
    const shader = gl.createShader(shader_type);
    if (shader == 0)
        return error.OpenGlFailure;
    errdefer gl.deleteShader(shader);

    var sources = [_][*c]const u8{source.ptr};
    var lengths = [_]gl.GLint{@intCast(source.len)};

    gl.shaderSource(shader, 1, &sources, &lengths);

    gl.compileShader(shader);

    var compile_status: gl.GLint = undefined;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &compile_status);

    if (compile_status != gl.TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.getShaderInfoLog(shader, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{s}", .{info_log});

        return error.InvalidShader;
    }

    return shader;
}

pub fn main() !void {
    var gameWindow = try Window.createWindow();
    defer gameWindow.destroyWindow();

    try gl.load(gameWindow.context, getProcAddress);

    // Initialize and create the OpenGL structures:

    // compile the shader program
    const triangle_program = try compileShader(
        global_allocator,
        @embedFile("triangle.vert"),
        @embedFile("triangle.frag"),
    );
    defer gl.deleteProgram(triangle_program);

    var vertex_buffer: gl.GLuint = 0;
    gl.genBuffers(1, &vertex_buffer);
    if (vertex_buffer == 0)
        return error.OpenGlFailure;
    defer gl.deleteBuffers(1, &vertex_buffer);
    //
    const vertices = [_]Vertex{
        Vertex{ // top
            .x = 0,
            .y = 0.5,
            .u = 1,
            .v = 0,
        },
        Vertex{ // bot left
            .x = -0.5,
            .y = -0.5,
            .u = 0,
            .v = 1,
        },
        Vertex{ // bot right
            .x = 0.5,
            .y = -0.5,
            .u = 1,
            .v = 1,
        },
    };

    gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);

    var vao: gl.GLuint = 0;
    gl.genVertexArrays(1, &vao);
    if (vao == 0)
        return error.OpenGlFailure;
    defer gl.deleteVertexArrays(1, &vao);

    gl.bindVertexArray(vao);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
    gl.enableVertexAttribArray(0); // Position attribute
    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "x")));
    gl.enableVertexAttribArray(1); // UV attributte
    gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "u")));
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.useProgram(triangle_program);
    gl.bindVertexArray(vao);

    while (!gameWindow.shouldQuit) {

        gameWindow.handleInput();
        // c.SDL_RenderPresent(renderer);

        gl.drawArrays(gl.TRIANGLES, 0, 3);
        gameWindow.draw();
    }
}
