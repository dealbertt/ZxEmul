const std = @import("std");
const print = @import("std").debug.print;

//We declare and initialize the registers to 0
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'

const memorySize: u16 = 16368;

//this 8 bit registers are: 
//A, B, C, D, E, H, or L
var A: u8 = 0;
var B: u8 = 0;
var C: u8 = 0;
var D: u8 = 0;
var E: u8 = 0;
var F: u8 = 0;
var L: u8 = 0;

//idk really know what to do with the "ghost" registers

//and then we have the "shadow" registers

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


fn op_nop() void{}
fn op_ld_a_n() void{ A = 1;}
fn op_ld_b_c() void{ B = C;}
fn op_unknown() void{print("Unknown opcode\n", .{});}

const OpcodeHandler = *const fn() void;
var mainOpcodes: [256]OpcodeHandler = [_]*const fn() void{op_unknown} ** 256;


pub fn initTables() void{
    for(0..256) |index| {
        mainOpcodes[index] = op_unknown;
    }
}

//This would be similar to C's typedef
pub fn fetch() !u8 {
    opcode = memory[pc];
    std.debug.print("Current opcode: {} \n", .{opcode});

    //if its a normal, 1 byte opcode, the instruction is already known
    //if its a prefix, CB, ED, DD, or FD, then it must fetch another byte
    //we might also need to fetch other operands, depending on the instruction
    //
    switch (opcode) {
        0xCB => print("Prefix CB opcode\n", .{}),
        0xED => print("Prefix CB opcode\n", .{}),
        else => {
            
        }
    }
    return opcode;
}

//function to load the specified program, idk if its going to be throught a command line- argument
pub fn loadProgram() !u8 {
    initTables();
    return 0;
}

//this only loads an 8 bit value onto an 8bit register?
//idk how i am going to handle the different loading (between 8 and 16 bit values)
//and the different addressing modes
//pub fn load_n (register: u8, value: u8) !void {
    
//}
