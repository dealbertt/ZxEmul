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


    const rom_size = try file.getEndPos();
    std.debug.print("Size of the file: {}\n", .{rom_size});

    if(rom_size > 16384){
        std.debug.print("The size of the ROM selected is too big!", .{});
        return error.romSizeTooBig; 
    }
    
    const bytes_read = try file.read(&comps.memory);


    std.debug.print("Bytes read: {}\n", .{bytes_read});
    return 0;
}

pub fn fetch() !u8 {

    return 0;
}


pub fn decode() !u8 {
    return 0;
}
