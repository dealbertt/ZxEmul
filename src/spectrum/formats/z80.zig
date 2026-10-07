const std = @import("std");

const s = @import("../../z80/internals/state.zig");
const h = @import("../../z80/instructions/helpers.zig");

const Z80_HEADER_SIZE = 30;

pub fn loadZ80file(file: std.Io.File, state: *s.State, io: std.Io) !void {
    const program_size = try file.length(io);
    std.debug.print("Size of the user program: {}\n", .{program_size});

    //the size varies (the memory is usually compressed), so the only certain thing is that the header has to fit
    if(program_size < Z80_HEADER_SIZE){
        std.debug.print("A .z80 file needs at least {} bytes for the header, this file has {}\n", .{ Z80_HEADER_SIZE, program_size });
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

    //bit 7 of R is not stored in byte 11 (whatever it holds there is not significant), it is bit 0 of this byte
    const bit7_r = (packed_bits & 0x01) << 7;

    state.r = (state.r & 0x7F) | bit7_r;

    state.bus.border_color = (packed_bits >> 1) & 0x07;

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

    //reset just in case
    state.halted = false;
    state.ei_defer = false;
    state.bus.int_req = false;

    var header_length: u16 = undefined; 
    if(check_pc != 0){
        state.pc = check_pc;
        try loadV1(&reader.interface, state, is_compressed);
    }else{
        header_length = try reader.interface.takeInt(u16, .little);
        state.pc = try reader.interface.takeInt(u16, .little);

        const hardware_mode = try reader.interface.takeByte();
        if(hardware_mode > 1) return error.unsupportedMode;

        try reader.interface.discardAll(header_length - 3);
        try loadBlocks(&reader.interface, state); 
    }
}

fn loadV1(reader: *std.Io.Reader, state: *s.State, is_compressed: bool) !void {
   if(!is_compressed){
       try reader.readSliceAll(state.bus.memory[0x4000..]);
   }else {
       //memory is compressed, wallahi     
       //Run length encoding
       _ = try decompress(reader, state.bus.memory[0x4000..]);        
   }
}

//For both V2 and V3
fn loadBlocks(reader: *std.Io.Reader, state: *s.State) !void {
    while(true){
        _ = reader.peekByte() catch |e| {
            if(e == error.EndOfStream) break;
            return e;
        };

        const length = try reader.takeInt(u16, .little); 
        const page_number = try reader.takeByte(); 

        //a ROM page has no place in memory, but its bytes still have to be read past to reach the next block
        const start = try pageStarts(page_number) orelse {
            //discardAll takes size as an argument, which you need to figure if its compressed or not
            try reader.discardAll(if(length == 0xFFFF) 0x4000 else length);
            continue;
        };
        const start_address: usize = start;
        if(length != 0xFFFF){
            _ = try decompress(reader, state.bus.memory[start_address..][0..0x4000]);
        }else{
            try reader.readSliceAll(state.bus.memory[start_address..][0..0x4000]);
        }
    }
}

fn pageStarts(page: u8) !?u16 {
        return switch (page) {
            4 => 0x8000,
            5 => 0xC000,
            8 => 0x4000,
            0, 1, 11 => null,
            else => error.pageNotImplemented,
        };
}

//decodes the z80 snapshot compression into dest, reading from the stream until dest is full.
//ED ED xx yy means byte yy repeated xx times. a single ED is stored as it is, and the byte right after it is never part of a code.
//returns how many compressed bytes it consumed, so the v2/v3 caller can check it against the block length.
//a repeat that does not fit in what is left of dest, or a stream that ends early, is an error
fn decompress(reader: *std.Io.Reader, dest: []u8) !usize {
    var written: usize = 0;
    var consumed: usize = 0;

    while(written < dest.len){
        const byte = try reader.takeByte();
        consumed += 1;

        if(byte != 0xED){
            //its a plain byte
            dest[written] = byte;
            written += 1;
        }else{
            //starts with ED
            const next = try reader.takeByte();
            consumed += 1;

            if(next == 0xED){
                //repeated count
                const xx = try reader.takeByte(); 

                const yy = try reader.takeByte();
                consumed += 2;

                if(xx > dest.len - written) return error.invalidCompressedData;
                @memset(dest[written..written + xx], yy);
                written += xx;
            }else{
                //ED and its plain byte
                if(written + 2 > dest.len) return error.invalidCompressedData;
                dest[written] = 0xED; 
                written += 1;

                dest[written] = next;
                written += 1;
            }
        }
    }
    return consumed;
}
