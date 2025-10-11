const std = @import("std");

//We declare and initialize the registers to 0
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'

const memorySize: u16 = 16368;

var reg8bit: [18]u8 = [_]u8{0x00} ** 18;
//this 8 bit registers are: 
//A, B, C, D, E, H, or L
//and then we have the "shadow" registers
var reg16bit: [4]u16 = [_]u16{0x0000} ** 4;

//INDEX REGISTERS 
var ix: u16 = 0x0000;
var iy: u16 = 0x0000;

var memory: [memorySize]u8 = [_]u8{0x00} ** memorySize;
//STACK POINTER
var sp: []u16 = [_]u16{0x0000} ** 16; //last-in first-out (LIFO)
                                //
//PROGRAM COUNTER
var pc: u16 = 0x0000;
var opcode: u16 = 0x0000;

pub fn fetch() !u8 {
    opcode = memory[pc];
    std.debug.print("Current opcode: {} \n", .{opcode});

    //if its a normal, 1 byte opcode, the instruction is already known
    //if its a prefix, CB, ED, DD, or FD, then it must fetch another byte
    //we might also need to fetch other operands, depending on the instruction
    //
    switch (opcode) {
       0x00 => std.debug.print("NOP\n", .{}), 
       0x01 => std.debug.print("LD\n", .{}),
       else => unreachable,
    }
    return opcode;
}

//function to load the specified program, idk if its going to be throught a command line- argument
pub fn loadProgram() !u8 {
    
}

//this only loads an 8 bit value onto an 8bit register?
//idk how i am going to handle the different loading (between 8 and 16 bit values)
//and the different addressing modes

//pub fn load_n (register: u8, value: u8) !void {
    
//}
