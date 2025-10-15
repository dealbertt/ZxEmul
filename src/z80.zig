const std = @import("std");
const print = @import("std").debug.print;

//KEEP IN MIND THAT THE Z80 IS LITTLE ENDIAN
//We declare and initialize the registers to 0
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'


const memorySize: u16 = 16368;

const regPair = extern union{
    pair: u16,
    bytes: extern struct{
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

const FLAG_C: u8 = 0b0000_0001;
const FLAG_N: u8 = 0b0000_0010;
const FLAG_P: u8 = 0b0000_0100;
const FLAG_H: u8 = 0b0001_0000;
const FLAG_Z: u8 = 0b0100_0000;
const FLAG_S: u8 = 0b1000_0000;

const registers = struct{
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

var cpu = registers{.af = .{ .pair = 0 },
    .bc = .{ .pair = 0 },
    .de = .{ .pair = 0 },
    .hl = .{ .pair = 0 },
    .ix = 0,
    .iy = 0,
    .sp = 0,
    .pc = 0
};


var memory: [memorySize]u8 = [_]u8{0x00} ** memorySize;
//STACK POINTER
                                //
//PROGRAM COUNTER
var opcode: u16 = 0x0000;



const OpcodeHandler = *const fn() void;
var mainOpcodes: [256]OpcodeHandler = [_]*const fn() void{op_unknown} ** 256;


//function created to load all of the opcode functions into the opcode arrays/lookup table
pub fn initTables() void{

    for(0..256) |index| {
        mainOpcodes[index] = op_unknown;
    }
    mainOpcodes[0x00] = op_nop;
    mainOpcodes[0x01] = op_ld_bc_nn;
    mainOpcodes[0x02] = op_ld_a_bc_addr;
    mainOpcodes[0x03] = op_inc_bc;
    mainOpcodes[0x04] = op_inc_b;
    mainOpcodes[0x05] = op_dec_b;
    mainOpcodes[0x06] = op_ld_b_n;
    mainOpcodes[0x07] = op_rlca;
    mainOpcodes[0x08] = op_ex_af_af_shadow;
    mainOpcodes[0x09] = op_add_hl_bc;
    mainOpcodes[0x0A] = op_ld_a_bc_addr;
    mainOpcodes[0x0B] = op_dec_bc;
    mainOpcodes[0x0C] = op_inc_c;
    mainOpcodes[0x0D] = op_dec_c;
    mainOpcodes[0x0E] = op_ld_c_n;
    mainOpcodes[0x0F] = op_rrca;

    mainOpcodes[0x10] = op_djnz_d;
    mainOpcodes[0x11] = op_ld_de_nn;
    mainOpcodes[0x12] = op_ld_a_de_addr;
    mainOpcodes[0x13] = op_inc_de;
    mainOpcodes[0x14] = op_inc_d;
    mainOpcodes[0x15] = op_dec_d;
    mainOpcodes[0x16] = op_ld_d_n;


}

//This would be similar to C's typedef
pub fn fetch() !u8 {
    opcode = memory[cpu.pc];
    cpu.pc += 1;
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

fn read_nn(addr: u16) u16{
    const lo = memory[addr];
    const hi = memory[addr + 1];
    return @as(u16, hi) << 8 | lo;
}
//Opcode 00
fn op_nop() void{
    return;
}

//Opcode 01
fn op_ld_bc_nn() void{
    const nn = read_nn(cpu.pc);
    cpu.pc += 2;
    cpu.bc.pair = nn;
}

//Opcode 02
fn op_ld_bc_addr_a() void{
   memory[cpu.bc.pair] = cpu.af.bytes.hi; 
}

//Opcode 03
fn op_inc_bc() void{
    cpu.bc.pair += 1;
}

//Opcode 04
fn op_inc_b() void {
    cpu.bc.bytes.hi += 1;
}

//Opcode 05
fn op_dec_b() void {
    cpu.bc.bytes.hi -= 1;
}

//Opcode 06
fn op_ld_b_n() void {
    cpu.bc.bytes.hi = memory[cpu.pc];
    cpu.pc += 1;
}

//Opcode 07
fn op_rlca() void {
    //1111 1110
    //Extract the bit 7, and set it in the LSB, given that its going to be
    //copied into the LSB of A and F.
    const bit7: u8 = (cpu.af.bytes.hi >> 7) & 1;
    //0000 0001

    //Once we have that, we set A, to the contents of A
    //shifted 1 bit to the left or bit7 -> a circular rotation
    //because bit0 now has the contents of bit 7
    //
    //Reset the N and H flag
    cpu.af.bytes.hi = ((cpu.af.bytes.hi << 1) | bit7) & 0xFF;
    //because we shift to the left, zig might promote to a bigger value, but we only
    //want to keep the lowest 8 bits
    //thi is basically a NOT of FLAG_C or FLAG_N or FLAG_H
    //0000 0001]
    //or       ] -> 0000 0011]
    //0000 0010]    or       ] -> 0001 0011
    //                              not
    //or       ] -> 0001 0000]    1110 1100
    //0001 0000]   
    //
    //this basically means that no matter the value, it will reset those flags to 0
    cpu.af.bytes.lo &= ~(FLAG_C | FLAG_N | FLAG_H);
    //even tho its not necessary, we also reset flag C, because it will be set 
    //to the value of bit7 of A
    cpu.af.bytes.lo |= bit7;
}

//Opcode 08
fn op_ex_af_af_shadow() void {
    return;
}

//Opcode 09
fn op_add_hl_bc() void {
    cpu.hl.pair += cpu.bc.pair;
}

//Opcode 0A
fn op_ld_a_bc_addr() void {
    cpu.af.bytes.hi = memory[cpu.hl.pair];
}

//Opcode 0B
fn op_dec_bc() void {
    cpu.bc.pair += 1;
}

//Opcode 0C
fn op_inc_c() void {
    cpu.bc.bytes.lo += 1;
}

//Opcode 0D
fn op_dec_c() void {
    cpu.bc.bytes.lo -= 1;
}

//Opcode 0E
fn op_ld_c_n() void {
    cpu.bc.bytes.lo = memory[cpu.pc];
    cpu.pc += 1;
}

//Opcoe 0F
fn op_rrca() void {
}

//Opcode 10
fn op_djnz_d() void {
    //this when
    const offset = @as(i8, memory[cpu.pc]);
    cpu.bc.bytes.hi -= 1;
    if(cpu.bc.bytes.hi != 0){
        //We want to take the 16bit pc(u16), add a signed 8bit offset,
        //and store it back as a u16
        cpu.pc = @as(u16, @intCast(@as(i16, cpu.pc) + @as(i16, offset))); 
    }
}

//Opcode 11
fn op_ld_de_nn() void {
    //the pc has been incremented, meaning that i am going to get the high bytes of nn 
    const nn: u16 = read_nn(cpu.pc);
    cpu.pc += 2;
    cpu.de.pair = nn;
}

//Opcode 12
fn op_ld_a_de_addr() void {
    memory[cpu.de.pair] = cpu.af.bytes.hi;
}

//Opcode 13
fn op_inc_de() void {
    cpu.de.pair += 1;
}

//Opcode 14
fn op_inc_d() void {
    cpu.de.bytes.hi += 1;
}

//Opcode 15
fn op_dec_d() void {
    cpu.de.bytes.hi -= 1;
}

//Opcode 16
fn op_ld_d_n() void {
    cpu.de.bytes.hi = memory[cpu.pc];
    cpu.pc += 1;
}


//Opcode unknown
fn op_unknown() void{print("Unknown opcode\n", .{});}
