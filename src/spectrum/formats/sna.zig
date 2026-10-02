const std = @import("std");
const s = @import("../../z80/internals/state.zig");

const PROGRAM_MEMORY_LIMIT = 49179;

pub fn loadSnapshot(file: std.Io.File, state: *s.State, io: std.Io) !void {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    //a file of this format needs to have this exact size
    if(program_size !=  PROGRAM_MEMORY_LIMIT){
        std.debug.print("The size of the program selected is too big!", .{});
        return error.programSizeTooBig; 
    }

    var scratch: [4096]u8 = undefined;
    var reader = file.reader(io, &scratch);
    
    //Offset 0x00
    state.i = try reader.interface.takeByte();

    //Offset 0x01
    state.hl_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x03
    state.de_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x05
    state.bc_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x07
    state.af_shadow.pair = try reader.interface.takeInt(u16, .little);
    
    //Offset 0x09
    state.hl.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x0B
    state.de.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x0D
    state.bc.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x0F
    state.iy = try reader.interface.takeInt(u16, .little);

    //Offset 0x11
    state.ix = try reader.interface.takeInt(u16, .little);

    //Offset 0x13
    state.iff2 = ((try reader.interface.takeByte()) & 0x02) != 0;

    //Offset 0x14
    state.r = try reader.interface.takeByte();

    //Offset 0x15
    state.af.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x17
    state.sp = try reader.interface.takeInt(u16, .little);

    //Offset 0x19
    state.im = @enumFromInt(try reader.interface.takeByte());

    //Offset 0x1A
    state.bus.border_color = try reader.interface.takeByte();  

    //Then the RAM
    //Offset 0x1B
    const bytes_read = try reader.interface.readSliceShort(self.cpu.state.bus.memory[0x5CCB .. 0x5CCB + program_size]);

}

