const std = @import("std");

const comps = @import("z80_internals.zig");

const inst = @import("../instructions/initTables.zig");

const print = std.debug.print;

const ROM_MEMORY_LIMIT = 16384;

pub fn setup() !u8{
    //load the initTables
    inst.initTables();
    initRegs();

    //i might have to do other things like initializing the screen, audio, keyboard, etc
    return 0;
}

fn initRegs() void {
    //Set all registers to 0 
    comps.cpu.af.pair = 0;
    comps.cpu.bc.pair = 0;
    comps.cpu.de.pair = 0;
    comps.cpu.hl.pair = 0;
    comps.cpu.ix = 0;
    comps.cpu.iy = 0;

    //Set the pc to the where the ram memory starts
    comps.cpu.pc = ROM_MEMORY_LIMIT;
}


pub fn loadProgram(path: []const u8) !u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();


    const rom_size = try file.getEndPos();
    std.debug.print("Size of the file: {}\n", .{rom_size});

    if(rom_size > ROM_MEMORY_LIMIT){
        std.debug.print("The size of the ROM selected is too big!", .{});
        return error.romSizeTooBig; 
    }
    
    const bytes_read = try file.read(&comps.memory);


    std.debug.print("Bytes read: {}\n", .{bytes_read});
    return 0;
}

pub fn read8(addr: u16) u8{
    return comps.memory[addr];
}


pub fn write8(addr: u16, value: u8) void {
    if(addr >= ROM_MEMORY_LIMIT){
        comps.memory[addr] = value;
    }
    //CANNOT WRITE TO ROM MEMORY
} 

pub fn fetch() !u8 {
    comps.opcode = read8(comps.cpu.pc);
    comps.cpu.pc += 1;
    std.debug.print("Current opcode {} \n", .{comps.opcode});

    //if its a normal, 1 byte z80.opcode, the instruction is already known
    //if its a prefix, CB, ED, DD, or FD, then it must fetch another byte
    //we might also need to fetch other operands, depending on the instruction
    //
    //switch (comps.opcode) {
    //   0xCB => print("Prefix CB z80.opcode\n", .{}),
    //   0xED => print("Prefix CB z80.opcode\n", .{}),
        //else => {},
    //}
    return comps.opcode;
}


pub fn decode() !u8 {
    return 0;
}
