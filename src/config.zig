const std = @import("std");
const cwd = std.fs.cwd();

const configPath = "config/config.txt";

pub const emulConfig = struct{
    height: u16,
    width: u16,
    debug: bool,
    fps: u8,
    pub fn reportConfig(self: emulConfig) void{
        std.debug.print("Window Width: {}\n", .{self.width});
        std.debug.print("Window Height: {}\n", .{self.height});
        std.debug.print("FPS: {}\n", .{self.fps});
    }
    
};


pub fn loadConfig() !emulConfig{
    var file = try cwd.openFile(configPath, .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    var inStream = bufReader.reader();

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("Line: {s}\n", .{line});
    }

    return null;
}
