const std = @import("std");

const comps = @import("z80_internals.zig");

const inst = @import("../instructions/initTables.zig");

pub fn setup() !u8{
    //load the initTables
    inst.initTables();

    //i might have to do other things like initializing the screen, audio, keyboard, etc
    return 0;
}


pub fn loadProgram(path: []const u8) !u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf:[4096]u8 = undefined;
    var reader = file.reader(&buf);

     while(true){
        const line = reader.interface.takeDelimiterExclusive('\n') catch |e| {
            if(e == error.EndOfStream) break;
            return e;
        };

        std.debug.print("Line: {s}\n", .{line});
    }
}

pub fn fetch() !u8 {

    return 0;
}


pub fn decode() !u8 {
    return 0;
}
