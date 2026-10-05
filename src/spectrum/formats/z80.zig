const std = @import("std");

const s = @import("../../z80/internals/state.zig");
const h = @import("../../z80/instructions/helpers.zig");

const Z80_48K_SIZE = 49179;

pub fn loadZ80file(file: std.Io.File, state: *s.State, io: std.Io) !void {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    //a file of this format needs to have this exact size
    if(program_size != Z80_48K_SIZE){
        std.debug.print("A 48K snapshot must be exactly {} bytes, this file has {}\n", .{ Z80_48K_SIZE, program_size });
        return error.invalidSnapshotSize;
    }

    var scratch: [4096]u8 = undefined;
    var reader = file.reader(io, &scratch);
    
    //Offset 0x00
    state.af.bytes.hi = try reader.interface.takeByte();

    //Offset 0x01
    state.af.bytes.lo = try reader.interface.takeByte();

    //Offset 0x02
    state.bc.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x04
    state.hl.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x06
    const check_pc = try reader.interface.takeInt(u16, .little);


    //Offset 0x08
    state.sp = try reader.interface.takeInt(u16, .little);
    
    //Offset 0x0A
    state.i = try reader.interface.takeByte();

    //Offset 0x0B
    state.r = try reader.interface.takeByte();

    //Offset 0x0C
    const packed_bits = try reader.interface.takeByte();

    const bit7_r = packed_bits << 7;

    state.r |= bit7_r;

    state.bus.border_color = packed_bits & 0x0E;

    const is_compressed: bool = (packed_bits & 0x20) != 0;

    //Offset 0x0D
    state.de.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x0F
    state.bc_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x11
    state.de_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x13
    state.hl_shadow.pair = try reader.interface.takeInt(u16, .little);

    //Offset 0x15
    state.af_shadow.bytes.hi = try reader.interface.takeByte();

    //Offset 0x16
    state.af_shadow.bytes.lo = try reader.interface.takeByte();

    //Offset 0x17
    state.iy = try reader.interface.takeInt(u16, .little);
    
    //Offset 0x19
    state.ix = try reader.interface.takeInt(u16, .little);

    //Offset 0x1B
    state.iff1 = (try reader.interface.takeByte()) != 0;

    //Offset 0x1C
    state.iff2 = (try reader.interface.takeByte()) != 0;

    //Offset 0x1D
    state.im = @enumFromInt(try reader.interface.takeByte() & 0x03);

    var header_length: u8 = undefined; 
    if(check_pc != 0){
        state.pc = check_pc;
        loadV0(reader, state, is_compressed);
    }else{
        header_length = try reader.interface.takeByte();
    }
}

fn loadV0(reader:std.Io.Reader, state: *s.State, is_compressed: bool) void {
   if(!is_compressed){
       try reader.interface.readSliceAll(state.bus.memory[0x4000..]);
   }else {
       //memory is compressed, wallahi     
       //Run length encoding

   }
}
