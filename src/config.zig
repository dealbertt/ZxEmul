const std = @import("std");
const print = @import("std").debug.print;
const cwd = std.fs.cwd();

const c = @cImport(@cInclude("stdio.h"));


const configPath = "data/config.txt";

pub const emulConfig = struct{
    height: u16,
    width: u16,
    debug: bool,
    fps: u8,
    pub fn reportConfig(self: emulConfig) void{
        print("Window Width: {}\n", .{self.width});
        print("Window Height: {}\n", .{self.height});
        print("FPS: {}\n", .{self.fps});
        print("Debug: {}\n", .{self.debug});
    }
    
};

pub fn loadConfig() !emulConfig{

    //We open the file only to read it
    //var file = try cwd.openFile(configPath, .{.mode = .read_only});

    const file = c.fopen(configPath, "r");

    if(file == null){
        return error.FileNotFound;
    }
    var line: [100]u8 = undefined;

    //var buf: [256]u8 = undefined;
    //var reader = file.reader(&buf).interface;

    //we declare a default config (until i can change the values from the config file, this tays as a const)
    const cfg: emulConfig = emulConfig{
        .width = 1280,
        .height = 720,
        .debug = false,
        .fps = 60,
    };

    //given that in C, an array is pointer to the first element, we quite literally have to do that in Zig.
    //
    while(c.fgets(&line[0], line.len , file) != null){
        var end: usize = 0;
        while(end < line.len and line[end] != 0): (end += 1){}

        const slice = line[0..end];
        const trimmed = std.mem.trim(u8, slice, "\t\r\n");
        
        print("Line: {s}\n", .{trimmed});
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

    }


    cfg.reportConfig();
    return cfg;
}
