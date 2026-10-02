const std = @import("std");
const s = @import("../../z80/internals/state.zig");
const h = @import("../../z80/instructions/helpers.zig");

const SNA_48K_SIZE = 49179;

pub fn loadSnapshot(file: std.Io.File, state: *s.State, io: std.Io) !void {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    //a file of this format needs to have this exact size
    if(program_size != SNA_48K_SIZE){
        std.debug.print("A 48K snapshot must be exactly {} bytes, this file has {}\n", .{ SNA_48K_SIZE, program_size });
        return error.invalidSnapshotSize;
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
    state.iff2 = ((try reader.interface.takeByte()) & 0x04) != 0;


    //Offset 0x14
    state.r = try reader.interface.takeByte();

    //Offset 0x15
    state.af.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x17
    state.sp = try reader.interface.takeInt(u16, .little);

    //Offset 0x19
    //the byte comes from the file, so it is checked: an out of range value is illegal for the enum
    const interrupt_mode = try reader.interface.takeByte();
    if(interrupt_mode > 2){
        std.debug.print("Invalid interrupt mode in the snapshot: {}\n", .{interrupt_mode});
        return error.invalidInterruptMode;
    }
    state.im = @enumFromInt(interrupt_mode);

    //Offset 0x1A
    state.bus.border_color = (try reader.interface.takeByte()) & 0x07;

    //Offset 0x1B
    try reader.interface.readSliceAll(state.bus.memory[0x4000..]);

    state.pc = h.pop16BitValue(state);
    state.iff1 = state.iff2;

    //reset just in case
    state.halted = false;
    state.ei_defer = false;
    state.bus.int_req = false;
}

