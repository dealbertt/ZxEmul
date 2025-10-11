const std = @import("std");
const rl = @import("raylib");

const height: u16 = 1280;
const width: u16 = 720;

pub fn main() !void {
    rl.initWindow(height, width, "ZxSpectrum emulator"); 
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    while(!rl.windowShouldClose()){

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        
        rl.drawText("Welcome to the ZXSpectrum emulator", height / 2, width / 2, 20, .light_gray);
    }
}

