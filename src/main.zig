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
    defer rl.closeWindow();

    const pos = rl.getWindowPosition();
    const monitor = rl.getCurrentMonitor();

    //to display the window in my principal monitor, having problems with the dual screen setup
    rl.setWindowMonitor(1);

    std.debug.print("Pos: {}\n", .{pos});
    std.debug.print("Monitor: {}\n", .{monitor});

    const texture = try createTexture();

    defer rl.unloadTexture(texture);
    rl.setTargetFPS(50);

    //the window size is fixed, so the screen position only needs computing once
    const position = centeredPosition(cfg.width, cfg.height, cfg.scale);

    while (!rl.windowShouldClose()) {
        comp.runFrame();
        rl.updateTexture(texture, &comp.video.frame_buffer);

        rl.beginDrawing();
        rl.clearBackground(.black);

        rl.drawTextureEx(texture, position, 0, cfg.scale, .white);
        rl.drawFPS(10, 10);

        rl.endDrawing();
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

//top-left corner that centres the scaled 256x192 screen in the window:
//the space left over on each axis is split evenly between both sides
fn centeredPosition(window_width: i32, window_height: i32, scale: f32) rl.Vector2 {
    const screen_width = 256 *  scale;
    const screen_height = 192 *  scale;

    //const x = @divTrunc(window_width - screen_width, 2);

    //const y = @divTrunc(window_height - screen_height, 2);

    const x = (@as(f32, @floatFromInt(window_width)) - screen_width) / 2.0;
    const y = (@as(f32, @floatFromInt(window_height)) - screen_height) / 2.0;
    return .{ .x = x, .y = y };
}

fn createTexture() !rl.Texture {
    const image = rl.genImageColor(256, 192, .black);
    defer rl.unloadImage(image);
    const texture = try rl.loadTextureFromImage(image);

    rl.setTextureFilter(texture, .point);

    return texture;
}


//so for the main loop, i kind of have two things to care about, the frame rate of the emulator, as in the whole program,
//and the frame rate of the cpu/computer itself which is 3,5mhz and 50hz, and idk if i should do that in timing.zig or directly in here

