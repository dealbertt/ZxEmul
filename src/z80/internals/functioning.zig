const std = @import("std");

const comps = @import("z80_internals.zig");

const inst = @import("../instructions/tables.zig");

const print = std.debug.print;


pub fn setup() !u8{
    //load the initTables
    inst.initTables();

    //i might have to do other things like initializing the screen, audio, keyboard, etc
    return 0;
}


pub fn read8(addr: u16) u8{
    return comps.memory[addr];
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
