const std = @import("std");
const rl = @import("raylib");

const config = @import("config/config.zig");
const spec = @import("spectrum/spectrum.zig");


//Todo on main:
//- Load the config
//- Initialize raylib
//- Get the path to the rom or program through a command line argument

const custom = error {
    argumentNotProvided,
    romSizeTooBig
};

const Emul = struct{
    window: rl.window
};
pub fn main(init: std.process.Init) !void {
    //load the config from the config file
    const cfg = try config.loadConfig(init);

    //handle args
    const rom_path =  try handleArgs(init);
    std.debug.print("PATH: {s}\n", .{rom_path});

    var comp:spec.Spectrum = undefined;

    try comp.init(rom_path, init);
    std.debug.print("AF: {}\n", .{comp.cpu.state.af.pair});

    rl.initWindow(cfg.width, cfg.height, "ZxEmul");

    const pos = rl.getWindowPosition();
    const monitor = rl.getCurrentMonitor();

    //to display the window in my principal monitor, having problems with the dual screen setup
    rl.setWindowMonitor(1);

    std.debug.print("Pos: {}\n", .{pos});
    std.debug.print("Monitor: {}\n", .{monitor});

    defer rl.closeWindow();

    rl.setTargetFPS(cfg.fps);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        rl.clearBackground(.white);
        rl.drawText("Welcome to the ZXSpectrum emulator", @divTrunc(cfg.width, 2),  @divTrunc(cfg.height, 2), 40, .red);

        rl.endDrawing();
        comp.runFrame();
        //update the buffer to refresh the screen 
    }
}

fn handleArgs(init: std.process.Init) ![]const u8 {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if(args.len < 2){
        std.debug.print("Please provide a path to the ROM to load!", .{});
        return custom.argumentNotProvided;
    }

    //return try alloc.dupe(u8, args[1]);
    return args[1];
}

//so for the main loop, i kind of have two things to care about, the frame rate of the emulator, as in the whole program,
//and the frame rate of the cpu/computer itself which is 3,5mhz and 50hz, and idk if i should do that in timing.zig or directly in here

