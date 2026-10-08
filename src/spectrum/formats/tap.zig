const std = @import("std");
const s = @import("../../z80/internals/state.zig");
const h = @import("../../z80/instructions/helpers.zig");

pub const Block = struct {
    flag: u8,
    start: usize, //where the block starts in data
    length: u16,
};

pub const Tape = struct{
    data: []u8,
    blocks: []Block,
    current: usize,

    pub fn fromTap(allocator: std.mem.Allocator, bytes: []u8 ) !Tape {
        var blocks = std.ArrayList(Block).init(allocator);
    
    }
};

pub fn loadTape(file: std.Io.File, io: std.Io) !Tape {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    var scratch: [4096]u8 = undefined;
    var reader = file.reader(io, &scratch);
    
    const length: u16 = try reader.interface.takeInt(u16, .little); 

    const flag: u8 = try reader.interface.takeByte(); 
}
