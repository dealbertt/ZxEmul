const std = @import("std");
const rl = @import("raylib");

const z80 = @import("z80/instructions/z80_opcodes.zig");
const config = @import("config.zig");

const print = std.debug.print;

//Todo on main:
//- Load the config
//- Initialize raylib
//- Get the path to the rom or program through a command line argument
//

pub fn main() !void {
    //const emulConfig = config.emulConfig { .width= 1280, .height= 720, .debug = false, .fps = 60 };
    const cfg = try config.loadConfig();

    rl.initWindow(cfg.width, cfg.height, "ZxSpectrum emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(cfg.fps);

    _ = try z80.loadProgram();
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawText("Welcome to the ZXSpectrum emulator", cfg.width / 2, cfg.height / 2, 40, .red);
    }
}
