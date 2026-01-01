const std = @import("std");
const rl = @import("raylib");

const inst = @import("z80/instructions/main_instructions.zig");
const config = @import("config.zig");
const func = @import("z80/internals/functioning.zig");


const print = std.debug.print;

//Todo on main:
//- Load the config
//- Initialize raylib
//- Get the path to the rom or program through a command line argument

const custom = error {
    argumentNotProvided,
    romSizeTooBig

};
pub fn main() !void {
    //const emulConfig = config.emulConfig { .width= 1280, .height= 720, .debug = false, .fps = 60 };
    const cfg = try config.loadConfig();
    _ = try func.setup();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const rom_path =  try handleArgs(alloc);
    defer alloc.free(rom_path);

    _ = try func.loadProgram(rom_path);


    rl.initWindow(cfg.width, cfg.height, "ZxSpectrum emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(cfg.fps);

    _ = try inst.loadProgram();
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawText("Welcome to the ZXSpectrum emulator", cfg.width / 2, cfg.height / 2, 40, .red);
    }
}

fn handleArgs(alloc: std.mem.Allocator) ![]const u8 {
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    

    if(args.len < 2){
        std.debug.print("Please provide a path to the ROM to load!", .{});
        return custom.argumentNotProvided;
    }

    return try alloc.dupe(u8, args[1]);
}
