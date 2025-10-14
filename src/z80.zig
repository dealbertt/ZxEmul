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
var H: u8 = 0;

var BC: *u16 = (B << 8) + C;
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



const OpcodeHandler = *const fn() void;
var mainOpcodes: [256]OpcodeHandler = [_]*const fn() void{op_unknown} ** 256;


//function created to load all of the opcode functions into the opcode arrays/lookup table
pub fn initTables() void{

    for(0..256) |index| {
        mainOpcodes[index] = op_unknown;
    }
    mainOpcodes[0x00] = op_nop;
    mainOpcodes[0x01] = op_ld_a_n;
    mainOpcodes[0x02] = op_ld_b_c;
}

//This would be similar to C's typedef
pub fn fetch() !u8 {
    opcode = memory[pc];
    pc += 1;
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

fn create16bitReg(firstReg: u8, secondReg: u8) u16{
    return (firstReg << 8) + secondReg;
}

fn assignValueFrom16Reg(firstReg: *u8, secondReg: *u8, reg16bit: u16) void{
   firstReg.* = reg16bit & 0xF0;  
   secondReg.* = reg16bit & 0x0F;  
}
fn op_nop() void{
    return;
}

fn op_ld_bc_nn() void{

    B = memory[pc];
    //We increment again to get the second byte of NN
    //
    pc += 1;
    C = memory[pc];
}

fn op_ld_bc_addr_a() void{
   memory[(B << 8) + C] = A; 
}

fn op_inc_bc() void{
    var bc = create16bitReg(B, C);
    bc += 1;

    assignValueFrom16Reg(&B, &C, bc);
}

fn op_inc_b() void {
    B += 1;
}

fn op_dec_b() void {
    B -= 1;
}

fn op_ld_b_n() void {
    B = memory[pc];
    pc += 1;
}

fn op_rlca() void {
    return;
}

fn op_ex_af_af_shadow() void {
    return;
}

fn op_add_hl_bc() void {
    var hl = create16bitReg(H, L);
    const bc = create16bitReg(B, C);

    hl += bc;
}


fn op_ld_a_n() void{ A = 1;}
fn op_ld_b_c() void{ B = C;}
fn op_unknown() void{print("Unknown opcode\n", .{});}
