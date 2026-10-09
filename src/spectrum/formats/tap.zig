const std = @import("std");
const s = @import("../../z80/internals/state.zig");
const h = @import("../../z80/instructions/helpers.zig");

pub const Block = struct {
    flag: u8,
    start: usize, //where the block starts in data
    length: u16,
};

const max_bytes = 10 * 1024 * 1024;

pub const Tape = struct{
    data: []u8,
    blocks: []Block,
    current: usize,

    pub fn fromTap(allocator: std.mem.Allocator, bytes: []u8 ) !Tape {
        var blocks: std.ArrayList(Block) = .empty; 

        var offset: usize = 0;

        while(offset < bytes.len) {
            //check if there is room for the length value (2 bytes)
            if((bytes.len - offset) < 2) return error.truncatedFile;

            const length = std.mem.readInt(u16, bytes[offset..][0..2], .little);

            if(length < 2 or (offset + length + 2) > bytes.len) return error.invalidBlockLength;

            var block: Block = undefined;

            block.flag = bytes[offset + 2]; 
                        
            //for the checksum and flag bytes
            block.length = length - 2;

            //the 2 bytes of length and the byte of flag
            block.start = offset + 3;

            try blocks.append(allocator, block);

            offset += @as(usize, length) + 2;
        }

        return .{
            .data = bytes,
            .blocks = try blocks.toOwnedSlice(allocator),
            .current = 0
        };
    }
};

pub fn loadTape(file: std.Io.File, io: std.Io, allocator: std.mem.Allocator) !Tape {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    if(program_size > max_bytes) return error.sizeTooLarge;

    var scratch: [4096]u8 = undefined;
    var reader = file.reader(io, &scratch);
    
    const contents: []u8= try reader.interface.readAlloc(allocator, program_size);

    return Tape.fromTap(allocator, contents);
}
