const std = @import("std");
const print = @import("std").debug.print;
const cwd = std.fs.cwd();

const c = @cImport(@cInclude("stdio.h"));


const configPath = "data/config.txt";

const emulConfig = struct{
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
    var cfg: emulConfig = emulConfig{
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
        
        //Skip empty lines or comments
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        //We split the values on the = sign 
        var splitter = std.mem.splitAny(u8, trimmed, "=");
        
        //we get the key
        const key = splitter.first();

        //we get the value
        const value = splitter.rest();

        if(std.mem.eql(u8, key, "WINDOW_WIDTH")){
            cfg.width = try std.fmt.parseInt(u16, value, 10);
            if(cfg.width > 1920) cfg.width = 1920;

        }else if(std.mem.eql(u8, key, "WINDOW_HEIGHT")){
            cfg.height= try std.fmt.parseInt(u16, value, 10);
            if(cfg.height > 1080) cfg.height = 1080;
        }else if(std.mem.eql(u8, key, "REFRESH_RATE")){
            cfg.fps = try std.fmt.parseInt(u8, value, 10);
            if(cfg.fps > 240) cfg.fps = 60;
        }

    }


    cfg.reportConfig();
    return cfg;
}
