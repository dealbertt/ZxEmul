const std = @import("std");
const rl = @import("raylib");

pub fn main() !void {
    rl.initWindow(1280, 720, "Zig raylib example"); 
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    while(!rl.windowShouldClose()){

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
    }
}

