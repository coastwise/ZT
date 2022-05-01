const gl = @import("gl");
const std = @import("std");
const builtin = @import("builtin");

const Self = @This();

id: c_uint = 0,
dead: bool = true,

const ShaderError = error{
    VertexCompilationError,
    FragmentCompilationError,
};

pub fn reportCompilationLog(shaderId: gl.GLuint) void {
    const maxLength: gl.GLsizei = 4096;
    var log: [maxLength]gl.GLchar = undefined;
    var logLength: gl.GLsizei = undefined;
    gl.glGetShaderInfoLog(shaderId, maxLength, &logLength, &log);
    std.debug.print("{s}\n", .{log[0..@intCast(usize, logLength)]});
}

pub fn reportProgramLog(programId: gl.GLuint) void {
    const maxLength: gl.GLsizei = 4096;
    var log: [maxLength]gl.GLchar = undefined;
    var logLength: gl.GLsizei = undefined;
    gl.glGetProgramInfoLog(programId, maxLength, &logLength, &log);
    std.debug.print("{s}\n", .{log[0..@intCast(usize, logLength)]});
}

pub fn from(shaderID: c_uint) Self {
    return .{
        .id = shaderID,
    };
}
pub fn init(vert: [*:0]const u8, frag: [*:0]const u8) Self {
    var self: Self = .{};

    var vertId = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    gl.glShaderSource(vertId, 1, &vert, null);
    gl.glCompileShader(vertId);

    var compileStatus: gl.GLint = undefined;
    gl.glGetShaderiv(vertId, gl.GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == gl.GL_FALSE) {
        if (builtin.mode == .Debug) {
            std.debug.print("Vertex Shader Compilation Error:\n", .{});
            reportCompilationLog(vertId);
        }
        return self;
    }

    var fragId = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource(fragId, 1, &frag, null);
    gl.glCompileShader(fragId);

    gl.glGetShaderiv(fragId, gl.GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == gl.GL_FALSE) {
        if (builtin.mode == .Debug) {
            std.debug.print("Fragment Shader Compilation Error:\n", .{});
            reportCompilationLog(fragId);
        }
        return self;
    }

    self.id = gl.glCreateProgram();
    gl.glAttachShader(self.id, vertId);
    gl.glAttachShader(self.id, fragId);
    gl.glLinkProgram(self.id);

    gl.glGetProgramiv(self.id, gl.GL_LINK_STATUS, &compileStatus);
    if (compileStatus == gl.GL_FALSE) {
        if (builtin.mode == .Debug) {
            std.debug.print("Program Link Error:\n", .{});
            reportProgramLog(self.id);
        }
        return self;
    }

    gl.glValidateProgram(self.id);
    gl.glGetProgramiv(self.id, gl.GL_VALIDATE_STATUS, &compileStatus);
    if (compileStatus == gl.GL_FALSE) {
        if (builtin.mode == .Debug) {
            std.debug.print("Program Validate Error:\n", .{});
            reportProgramLog(self.id);
        }
        return self;
    }

    gl.glDeleteShader(vertId);
    gl.glDeleteShader(fragId);

    gl.glUseProgram(0);

    self.dead = false;

    return self;
}
pub fn deinit(self: *Self) void {
    gl.glDeleteProgram(self.id);
    self.dead = true;
}
pub fn bind(self: *Self) void {
    gl.glUseProgram(self.id);
}
pub fn unbind(self: *Self) void {
    _ = self;
    gl.glUseProgram(0);
}
