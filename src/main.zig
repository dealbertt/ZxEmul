const std = @import("std");
const rl = @import("raylib");
const utils = @import("z80.zig");
const config = @import("config.zig");
const print = @import("std").debug.print;

//Todo on main:
//- Load the config
//- Initialize raylib
//- Get the path to the rom or program through a command line argument
//
//
//
//

pub fn main() !void {
    //const emulConfig = config.emulConfig { .width= 1280, .height= 720, .debug = false, .fps = 60 };
    const cfg = try config.loadConfig();

    rl.initWindow(cfg.width, cfg.height, "ZxSpectrum emulator"); 
    defer rl.closeWindow();

    rl.setTargetFPS(cfg.fps);
    
    while(!rl.windowShouldClose()){

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawText("Welcome to the ZXSpectrum emulator", cfg.width / 2, cfg.height / 2, 20, .red);
    }
}

