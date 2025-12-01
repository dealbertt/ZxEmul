pub const std = @import("std");

pub const memorySize: u16 = 16368;

pub const regPair = extern union { pair: u16, bytes: extern struct {
    lo: u8,
    hi: u8,
    }
};

//The F register is used for flags :
//Bit 7: Sign Flag
//Bit 6: Zero Flag
//Bit 5: Not used
//Bit 4: Half carry flag
//Bit 3: Not used
//Bit 2: Parity/Overflow flag
//Bit 1: Add/Substract Flag
//Bit 0: Carry Flag

pub const FLAG_C: u8 = 0b0000_0001;
pub const FLAG_N: u8 = 0b0000_0010;
pub const FLAG_P: u8 = 0b0000_0100;
pub const FLAG_H: u8 = 0b0001_0000;
pub const FLAG_Z: u8 = 0b0100_0000;
pub const FLAG_S: u8 = 0b1000_0000;

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

pub var cpu = registers{ .af = .{ .pair = 0 }, .bc = .{ .pair = 0 }, .de = .{ .pair = 0 }, .hl = .{ .pair = 0 }, .ix = 0, .iy = 0, .sp = 0, .pc = 0 };

pub var memory: [memorySize]u8 = [_]u8{0x00} ** memorySize;
//STACK POINTER
//
//PROGRAM COUNTER
pub var opcode: u16 = 0x0000;

