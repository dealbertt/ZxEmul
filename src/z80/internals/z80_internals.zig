pub const std = @import("std");

pub const memorySize: u32 = 65536;


//The F register is used for flags :
//Bit 7: Sign Flag
//Bit 6: Zero Flag
//Bit 5: Not used
//Bit 4: Half carry flag
//Bit 3: Not used
//Bit 2: Parity/Overflow flag
//Bit 1: Add/Substract Flag
//Bit 0: Carry Flag


pub const registers = struct {
    af: regPair,
    bc: regPair,
    de: regPair,
    hl: regPair,
    ix: u16,
    iy: u16,
    sp: u16,
    pc: u16,
};

//idk really know what to do with the "ghost" registers

//and then we have the "shadow" registers

pub var memory: [memorySize]u8 = [_]u8{0x00} ** memorySize;
//STACK POINTER
//
//PROGRAM COUNTER
pub var opcode: u16 = 0x0000;


