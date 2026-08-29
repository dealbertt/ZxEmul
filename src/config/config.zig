const std = @import("std");
const print = std.debug.print;


const configPath = "src/config/config.txt";

const emulConfig = struct{
    height: i32 = 1600,
    width: i32 = 900,
    debug: bool = false,
    fps: u8 = 60,

    pub fn reportConfig(self: emulConfig) void{
        print("Window Width: {}\n", .{self.width});
        print("Window Height: {}\n", .{self.height});
        print("FPS: {}\n", .{self.fps});
        print("Debug: {}\n", .{self.debug});
    }
    
};

pub fn loadConfig(init: std.process.Init) !emulConfig{

    const io = init.io;
    const file = try std.Io.Dir.cwd().openFile(io, configPath, .{.mode = .read_only});
    defer file.close(io);

    //deprecated method
    //const file = try std.fs.cwd().openFile(configPath, .{});

    var buf: [4096]u8 = undefined;
    var reader = file.reader(io, &buf);

    //var buf: [256]u8 = undefined;
    //var reader = file.reader(&buf).interface;

    //we declare a default config (until i can change the values from the config file, this tays as a const)
    var cfg: emulConfig = emulConfig{};

    while(true){
        const raw_line = reader.interface.takeDelimiterInclusive('\n') catch |e| {
            if(e == error.EndOfStream) break;
            return e;
        };

        const line = std.mem.trim(u8, raw_line, &std.ascii.whitespace);
        std.debug.print("Line: {s}\n", .{line});

        if(line.len == 0) continue;
        //We split the values on the = sign 
    
        var splitter = std.mem.splitScalar(u8, line, '=');
        
        //we get the key
        const key = std.mem.trim(u8, splitter.first(), &std.ascii.whitespace);

        //we get the value
        const value = std.mem.trim(u8, splitter.rest(), &std.ascii.whitespace);

        std.debug.print("Key: {s} | Value: {s}\n", .{ key, value });
        if(std.mem.eql(u8, key, "WINDOW_WIDTH")){
            cfg.width = try std.fmt.parseInt(i32, value, 10);
            std.debug.print("WINDOW_WIDTH set\n", .{});
            if(cfg.width > 1920) cfg.width = 1920;

        }else if(std.mem.eql(u8, key, "WINDOW_HEIGHT")){
            cfg.height= try std.fmt.parseInt(i32, value, 10);
            std.debug.print("WINDOW_HEIGHT set\n", .{});
            if(cfg.height > 1080) cfg.height = 1080;
        }else if(std.mem.eql(u8, key, "REFRESH_RATE")){
            cfg.fps = try std.fmt.parseInt(u8, value, 10);
            if(cfg.fps > 240) cfg.fps = 60;
        }

    }

    cfg.reportConfig();
    return cfg;
}
