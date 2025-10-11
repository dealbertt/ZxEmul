const std = @import("std");
const rl = @import("raylib");
const utils = @import("z80.zig");
const config = @import("config.zig");

//Todo on main:
//- Initialize raylib
//- Get the path to the rom or program through a command line argument
//
//
//
//

pub fn main() !void {
    const emulConfig = config.emulConfig { .width= 1280, .height= 720, .debug = false, .fps = 60 };
    //const emulConfig = config.loadConfig();

    rl.initWindow(emulConfig.width, emulConfig.height, "ZxSpectrum emulator"); 
    defer rl.closeWindow();

    rl.setTargetFPS(emulConfig.fps);

    emulConfig.reportConfig();
    while(!rl.windowShouldClose()){

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawText("Welcome to the ZXSpectrum emulator", emulConfig.width / 2, emulConfig.height / 2, 20, .red);
    }
}

