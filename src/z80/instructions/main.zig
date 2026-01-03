const std = @import("std");

const print = std.debug.print;
const z80 = @import("../internals/z80_internals.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

//TODO
//- implement the missing flag handles on ops like inc, dec, add, sub, etc,...

//KEEP IN MIND THAT THE Z80 IS LITTLE ENDIAN
//We declare and initialize the registers to 0
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'

//function to load the specified program, idk if its going to be throught a command line- argument

//gotta make a couple of optimizations for the first instructions like ld to use a template

fn add_16bitRegs(reg1: u16, reg2: u16) u16 {
    const sum = @addWithOverflow(reg1, reg2);
    if (sum[1] == 1) {
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }

    if(sum[0] == 0){
        //set the zero flag
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }

    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N); 
    return sum[0];
}

fn inc_8bitReg(reg: *u8) void{
    const inc = @addWithOverflow(reg.*, 1);
    if(inc[1] == 1){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }

    if(inc[0] == 0){
        //set the zero flag
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }


    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);
    reg.* = inc[0];
}

fn inc_16bitReg(reg: *u16) void{
    const inc = @addWithOverflow(reg.*, 1);
    if(inc[1] == 1){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }

    if(inc[0] == 0){
        //set the zero flag
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }


    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);
    reg.* = inc[0];
}

const Register = enum(u3){
    B, C, D, E, H, L, A, HL,
};

const RegisterPair = enum(u3){
    BC, DE, HL, AF,
};

fn getRegisterValue(r: Register) u8{
    return switch(r){
        .B => z80.cpu.bc.bytes.hi,
        .C => z80.cpu.bc.bytes.lo,
        .D => z80.cpu.de.bytes.hi,
        .E => z80.cpu.de.bytes.lo,
        .H => z80.cpu.hl.bytes.hi,
        .L => z80.cpu.hl.bytes.lo,
        .A => z80.cpu.af.bytes.hi,
        .HL=> z80.memory[z80.cpu.hl.pair]
    };
}

fn getRegisterPair(rp: RegisterPair) *z80.regPair {
    return switch(rp){
        .BC => &z80.cpu.bc,
        .DE => &z80.cpu.de,
        .HL => &z80.cpu.hl,
        .AF => &z80.cpu.af,
    };
}
fn setRegisterValue(r: Register, value: u8) void {
    switch(r){
        .B => z80.cpu.bc.bytes.hi = value,
        .C => z80.cpu.bc.bytes.lo = value,
        .D => z80.cpu.de.bytes.hi = value,
        .E => z80.cpu.de.bytes.lo = value,
        .H => z80.cpu.hl.bytes.hi = value,
        .L => z80.cpu.hl.bytes.lo = value,
        .A => z80.cpu.af.bytes.hi = value,
        .HL=> z80.memory[z80.cpu.hl.pair] = value,
    }
}


//pub fn add_offset(reg: u16, offset: i8) u16{
//return 0;
//}

//Opcode 00
//No operation is performed.
pub fn op_nop() void {
    return;
}

//Opcode 01
//Loads nn into BC.
//01 nn
//Bytes
//3
//Cycles
//10
//C unaffected
//N unaffected
//P/V unaffected
//H unaffected
//Z unaffected
//S unaffected

//Opcode unknown
pub fn op_unknown() void {
    print("Unknown opcode {}", .{z80.opcode});
}
pub fn op_ld_bc_nn() void {
    const nn = mem.read16(z80.cpu.pc);
    z80.cpu.pc += 2;
    z80.cpu.bc.pair = nn;
}

//Opcode 02
pub fn op_ld_bc_addr_a() void {
    z80.memory[z80.cpu.bc.pair] = z80.cpu.af.bytes.hi;
}

//Opcode 03
pub fn op_inc_bc() void {
    inc_16bitReg(&z80.cpu.bc.pair);
}

//Opcode 04
pub fn op_inc_b() void {
    inc_8bitReg(&z80.cpu.bc.bytes.hi);
}

//Opcode 05
pub fn op_dec_b() void {
    z80.cpu.bc.bytes.hi -= 1;
}

//Opcode 06
pub fn op_ld_b_n() void {
    z80.cpu.bc.bytes.hi = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

//Opcode 07
pub fn op_rlca() void {
    //1111 1110
    //LSB: Least significant bit
    //Extract the bit 7, and set it in the LSB, given that its going to be
    //copied into the LSB of A and F.
    const bit7: u8 = (z80.cpu.af.bytes.hi >> 7) & 1;
    //0000 0001

    //Once we have that, we set A, to the contents of A
    //shifted 1 bit to the left or bit7 -> a circular rotation
    //because bit0 now has the contents of bit 7
    //
    //Reset the N and H flag
    z80.cpu.af.bytes.hi = ((z80.cpu.af.bytes.hi << 1) | bit7) & 0xFF;
    //because we shift to the left, zig might promote to a bigger value, but we only
    //want to keep the lowest 8 bits
    //this is basically a NOT of z80.FLAG_C or FLAG_N or FLAG_H
    //0000 0001]
    //OR       ] -> 0000 0011]
    //0000 0010]        OR   ] -> 0001 0011
    //                              NOT
    //OR       ] -> 0001 0000]    1110 1100
    //0001 0000]
    //
    //this basically means that no matter the value, it will reset those flags to 0
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_C | z80.FLAG_N | z80.FLAG_H);
    //even tho its not necessary, we also reset flag C, because it will be set
    //to the value of bit7 of A
    z80.cpu.af.bytes.lo |= bit7;
}

//Opcode 08
pub fn op_ex_af_af_shadow() void {
    return;
}

//Opcode 09
pub fn op_add_hl_bc() void {
    z80.cpu.hl.pair += z80.cpu.bc.pair;
}

//Opcode 0A
pub fn op_ld_a_bc_addr() void {
    z80.cpu.af.bytes.hi = z80.memory[z80.cpu.hl.pair];
}

//Opcode 0B
pub fn op_dec_bc() void {
    z80.cpu.bc.pair += 1;
}

//Opcode 0C
pub fn op_inc_c() void {
    inc_8bitReg(&z80.cpu.bc.bytes.lo);
}

//Opcode 0D
pub fn op_dec_c() void {
    z80.cpu.bc.bytes.lo -= 1;
}

//Opcode 0E
pub fn op_ld_c_n() void {
    z80.cpu.bc.bytes.lo = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

//Opcoe 0F
pub fn op_rrca() void {
    const bit7: u8 = (z80.cpu.af.bytes.hi >> 7) & 1;

    z80.cpu.af.bytes.hi = ((z80.cpu.af.bytes.hi >> 1) | bit7) & 0xFF;
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_C | z80.FLAG_N | z80.FLAG_H);

    z80.cpu.af.bytes.lo |= bit7;
}

//Opcode 10
//THIS FUNCTIONS NEEDS A LOT OF TESTING
pub fn op_djnz_d() void {

    //this when
    //
    z80.cpu.bc.bytes.hi -%= 1;
    if (z80.cpu.bc.bytes.hi != 0) {
        //We want to take the 16bit pc(u16), add a signed 8bit offset,
        //and store it back as a u16
        const offset: i8 = @bitCast(z80.memory[z80.cpu.pc]);
        //z80.cpu.pc = @intCast(u16, @as(i16, z80.cpu.pc) + @as(i16, offset));
        const new_pc = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, offset);
        //z80.cpu.pc = @as(u16, @intCast(@as(i16, z80.cpu.pc) + @as(i16, offset)));
        z80.cpu.pc = @bitCast(@as(i16, new_pc));
    }
}

//Opcode 11
pub fn op_ld_de_nn() void {
    //the pc has been incremented, meaning that i am going to get the high bytes of nn
    const nn: u16 = mem.read16(z80.cpu.pc);
    z80.cpu.pc += 2;
    z80.cpu.de.pair = nn;
}

//Opcode 12
pub fn op_ld_a_de_addr() void {
    z80.memory[z80.cpu.de.pair] = z80.cpu.af.bytes.hi;
}

//Opcode 13
pub fn op_inc_de() void {
    inc_16bitReg(&z80.cpu.de.pair);
}

//Opcode 14
pub fn op_inc_d() void {
    inc_8bitReg(&z80.cpu.de.bytes.hi);
}

//Opcode 15
pub fn op_dec_d() void {
    z80.cpu.de.bytes.hi -= 1;
}

//Opcode 16
pub fn op_ld_d_n() void {
    z80.cpu.de.bytes.hi = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

//Opcode 17
//The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
pub fn rla() void {
    const bit7: u8 = (z80.cpu.af.bytes.hi >> 7) & 1;
    const prevCarry: u8 = z80.cpu.af.bytes.lo & 0x01; //get the last bit -> carry flag

    z80.cpu.af.bytes.hi = ((z80.cpu.af.bytes.hi << 1) | bit7) & 0xFF;
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_C | z80.FLAG_N | z80.FLAG_H);
    z80.cpu.af.bytes.lo |= bit7;

    //The previous contents of the Carry flag are copied to bit 0
    z80.cpu.af.bytes.hi |= prevCarry;
}

pub fn jr_d() void {
    const jump: i8 = @bitCast(z80.memory[z80.cpu.pc]);
    const new_pc: i16 = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, jump);

    z80.cpu.pc = @bitCast(@as(i16, new_pc));
}

pub fn op_add_hl_de() void {
    z80.cpu.hl.pair = add_16bitRegs(z80.cpu.hl.pair, z80.cpu.de.pair);
}

pub fn op_ld_de_addr_a() void {
    z80.cpu.af.bytes.hi = z80.memory[z80.cpu.de.pair];
}

pub fn op_dec_de() void {
    z80.cpu.de.pair -= 1;
}

pub fn op_inc_e() void {
    inc_8bitReg(&z80.cpu.de.bytes.lo);
}

pub fn op_dec_e() void {
    z80.cpu.de.bytes.lo -= 1;
}
pub fn op_ld_e_n() void {
    z80.cpu.de.bytes.lo = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

pub fn op_rra() void {
    const bit7: u8 = (z80.cpu.af.bytes.hi >> 7) & 1;
    const prevCarry: u8 = z80.cpu.af.bytes.lo & 0x01; //get the last bit -> carry flag

    z80.cpu.af.bytes.hi = ((z80.cpu.af.bytes.hi >> 1) | bit7) & 0xFF;
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_C | z80.FLAG_N | z80.FLAG_H);
    z80.cpu.af.bytes.lo |= bit7;

    //The previous contents of the Carry flag are copied to bit 0
    z80.cpu.af.bytes.hi |= prevCarry;
}

pub fn op_jr_nz() void {
    if ((z80.cpu.af.bytes.lo & z80.FLAG_Z) == 0) {
        //zero flag is not set
        const jump: i8 = @bitCast(z80.memory[z80.cpu.pc]);
        const new_pc: i16 = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, jump);

        z80.cpu.pc = @bitCast(@as(i16, new_pc));
    }
}

pub fn op_ld_hl_nn() void {
    const nn = mem.read16(z80.cpu.pc);
    z80.cpu.hl.pair = nn;

    z80.cpu.pc += 2;
}

pub fn op_ld_nn_addr_hl() void {
    const nn = mem.read16(z80.cpu.pc);
    z80.memory[nn] = z80.cpu.hl.bytes.lo;
    z80.memory[nn + 1] = z80.cpu.hl.bytes.hi;

    z80.cpu.pc += 2;
}

pub fn op_inc_hl() void {
    inc_16bitReg(&z80.cpu.hl.pair);
}

pub fn op_inc_h() void {
    inc_8bitReg(&z80.cpu.hl.bytes.hi);
}

pub fn op_dec_h() void {
    z80.cpu.hl.bytes.hi -= 1;
}

pub fn op_ld_h_n() void {
    z80.cpu.hl.bytes.hi = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

pub fn op_daa() void {}

pub fn op_jr_z() void {
    if ((z80.cpu.af.bytes.lo & z80.FLAG_Z) != 0) {
        //zero flag is not set
        const jump: i8 = @bitCast(z80.memory[z80.cpu.pc]);
        const new_pc: i16 = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, jump);

        z80.cpu.pc = @bitCast(@as(i16, new_pc));
        z80.cpu.pc += 1;
    }
}

pub fn op_add_hl_hl() void {
    z80.cpu.hl.pair += z80.cpu.hl.pair;
}

//1 byte for the z80.opcode?
//1 byte for
pub fn op_ld_hl_nn_addr() void {
    const nn = mem.read16(z80.cpu.pc);
    z80.cpu.hl.bytes.lo = z80.memory[nn];
    z80.cpu.hl.bytes.hi = z80.memory[nn + 1];

    z80.cpu.pc += 2;
}

pub fn op_dec_hl() void {
    z80.cpu.hl.pair -= 1;
}

pub fn op_inc_l() void {
    inc_8bitReg(&z80.cpu.hl.bytes.lo);
}

pub fn op_dec_l() void {
    z80.cpu.hl.bytes.lo -= 1;
}

pub fn op_ld_l_n() void {
    z80.cpu.hl.bytes.lo = z80.memory[z80.cpu.pc];
}

pub fn op_cpl() void {
    z80.cpu.af.bytes.hi = ~z80.cpu.af.bytes.hi;

    //Set the H and N flags
    z80.cpu.af.bytes.lo |= (z80.FLAG_H | z80.FLAG_C);
}

pub fn op_jr_nc() void {
    if ((z80.cpu.af.bytes.lo & z80.FLAG_C) == 0) {
        //Carry flag is not set
        const jump: i8 = @bitCast(z80.memory[z80.cpu.pc]);
        const new_pc: i16 = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, jump);

        z80.cpu.pc = @bitCast(@as(i16, new_pc));
        z80.cpu.pc += 1;
    }
}

pub fn op_ld_sp_nn() void {
    const nn = mem.read16(z80.cpu.pc);
    z80.cpu.sp = nn;

    z80.cpu.pc += 2;
}

pub fn op_ld_nn_addr_a() void {
    const nn = mem.read16(z80.cpu.pc);

    z80.memory[nn] = z80.cpu.af.bytes.hi;

    z80.cpu.pc += 2;
}

pub fn op_inc_sp() void {
    z80.cpu.sp += 1;
}

pub fn op_inc_hl_addr() void {
    //z80.memory[z80.cpu.hl.pair] += 1;
    inc_8bitReg(&z80.memory[z80.cpu.hl.pair]);
}

pub fn op_dec_hl_addr() void {
    z80.memory[z80.cpu.hl.pair] -= 1;
}

pub fn op_ld_hl_addr_n() void {
    z80.memory[z80.cpu.hl.pair] = z80.memory[z80.cpu.pc];
}

pub fn op_scf() void {
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_C | z80.FLAG_N | z80.FLAG_H);
    z80.cpu.af.bytes.lo |= z80.FLAG_C;
}

pub fn op_jr_c() void {
    if ((z80.cpu.af.bytes.lo & z80.FLAG_C) != 0) {
        //Carry flag is set
        const jump: i8 = @bitCast(z80.memory[z80.cpu.pc]);
        const new_pc: i16 = @as(i16, @bitCast(z80.cpu.pc)) + @as(i16, jump);

        z80.cpu.pc = @bitCast(@as(i16, new_pc));
        z80.cpu.pc += 1;
    }
}

pub fn op_add_hl_sp() void {
    z80.cpu.hl.pair += z80.cpu.sp;
}

pub fn op_ld_a_nn_addr() void {
    const nn = read_nn(z80.cpu.pc);
    z80.cpu.af.bytes.hi = z80.memory[nn];

    z80.cpu.pc += 2;
}

pub fn op_dec_sp() void {
    z80.cpu.sp -= 1;
}

pub fn op_inc_a() void {
    inc_8bitReg(&z80.cpu.af.bytes.hi);
}

pub fn op_dec_a() void {
    z80.cpu.af.bytes.hi -= 1;
}

pub fn op_ld_a_n() void {
    z80.cpu.af.bytes.hi = z80.memory[z80.cpu.pc];
    z80.cpu.pc += 1;
}

pub fn op_ccf() void {
    z80.cpu.af.bytes.lo ^= z80.FLAG_C;
}

fn op_ld(src: Register, dst: Register) void {
    const value = getRegisterValue(src);
    setRegisterValue(dst, value);
}

pub fn decode_ld() void {
    const src: Register = @enumFromInt(z80.opcode & 0b111);
    const dst: Register = @enumFromInt((z80.opcode >> 3) & 0b111);
    op_ld(src, dst);
}

fn op_add_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = add_a_value(value);
}

pub fn decode_add_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_add_a(src);
}

fn add_a_value(value: u8) u8{
    const add:u16 = @as(u16, z80.cpu.af.bytes.hi) + @as(u16, value);    

    const res: u8 = @truncate(add);


    if(res < 0){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }

    if(res == 0){
        //set the zero flag
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        z80.cpu.af.bytes.lo |= z80.FLAG_S;
    }
    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);

    return res;
}

fn op_adc_a(src: Register) void {
    var value: u8 = getRegisterValue(src);
    value += (z80.cpu.af.bytes.lo & z80.FLAG_C);
    z80.cpu.af.bytes.hi = adc_a_value(value);
}

pub fn decode_adc_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_adc_a(src);
}

fn adc_a_value(value: u8) u8{
    const carry = (z80.cpu.af.bytes.lo & z80.FLAG_C);
    const sum = @as(u16, value) + @as(u16, z80.cpu.af.bytes.hi) + carry;

    const res: u8 = @truncate(sum);

    if(sum > 0xFF){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }
    
    if(res == 0){
        //set the zero flag if result is 0 
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        z80.cpu.af.bytes.lo |= z80.FLAG_S;
    }

    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);

    return res;
}

fn op_sub_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = sub_a_value(value);
}

pub fn decode_sub_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_sub_a(src);
}

fn sub_a_value(value: u8) u8{
    const sub:u16 = @as(u16, z80.cpu.af.bytes.hi) - @as(u16, value);    

    const res: u8 = @truncate(sub);


    if(res < 0){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }

    if(res == 0){
        //set the zero flag
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        z80.cpu.af.bytes.lo |= z80.FLAG_S;
    }
    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);

    return res;
}

fn op_sbc_a(src: Register) void {
    const value = getRegisterValue(src);
    value += (z80.cpu.af.bytes.lo & z80.FLAG_C);
    z80.cpu.af.bytes.hi = sbc_a_value(value);
    
}

pub fn decode_sbc_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_sbc_a(src);
}

fn sbc_a_value(value: u8) u8{
    const carry = (z80.cpu.af.bytes.lo & z80.FLAG_C);
    const sum = @as(u16, value) - @as(u16, z80.cpu.af.bytes.hi) - carry;

    const res: u8 = @truncate(sum);

    //flags
    //carry flag
    if(sum > 0xFF){
        //set the carry flag if an overflow happened
        z80.cpu.af.bytes.lo |= z80.FLAG_C;
    }
    
    //zero flag
    if(res == 0){
        //set the zero flag if result is 0 
        z80.cpu.af.bytes.lo |= z80.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        z80.cpu.af.bytes.lo |= z80.FLAG_S;
    }

    //reset the N flag
    z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);

    return res;
}

const op = enum {
    And,
    Xor,
    Or
};

fn decode_binary_operation(value: u8, operation: op) u8 {
        var res: u8 = z80.cpu.af.bytes.hi;
        switch(operation){
            .And => res &= value,
            .Xor => res ^= value,
            .Or  => res |= value,
        }

        //reset the N flag
        z80.cpu.af.bytes.lo &= ~(z80.FLAG_N);

        //reset the C flag
        z80.cpu.af.bytes.lo &= ~(z80.FLAG_C);

        return res;
}

fn op_and_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = decode_binary_operation(value, .And);
}

pub fn decode_and_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_and_a(src);
}

fn op_xor_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = decode_binary_operation(value, .Xor);
}

pub fn decode_xor_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_xor_a(src);
}


fn op_or_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = decode_binary_operation(value, .Or);
}

pub fn decode_or_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_xor_a(src);
}


fn op_cp_a(src:Register) void {
    const value = getRegisterValue(src);
    z80.cpu.af.bytes.hi = cp_a_value(value);
}

pub fn decode_cp_a() void {
    const src: Register = @enumFromInt(z80.opcode & 0b1111);
    op_cp_a(src);
}

fn cp_a_value(value: u8) u8 {
    const sub:u16 = @as(u16, z80.cpu.af.bytes.hi) - @as(u16, value);    

    const res: u8 = @truncate(sub);

    return res;
}


pub fn ret_nz() void {
    if((z80.cpu.af.bytes.lo & z80.FLAG_Z) == 0){
        //pop  
        const lo = z80.memory[z80.cpu.sp];
        z80.cpu.sp += 1;

        const hi = z80.memory[z80.cpu.sp];
        z80.cpu.sp += 1;

        z80.cpu.pc = @as(u16, hi) << 8 | lo;
    }
}

fn op_pop_reg(src:RegisterPair) void {
    const pair = getRegisterPair(src);
    pop_reg(pair);
}

pub fn decode_pop_reg() void {
    const src: RegisterPair = @enumFromInt(@as(u3, @intCast((z80.opcode >> 4) & 0b11)));
    op_pop_reg(src);
}

fn pop_reg(regPair: *z80.regPair) void {
    regPair.bytes.lo = z80.memory[z80.cpu.sp];
    z80.cpu.sp += 1;

    regPair.bytes.hi = z80.memory[z80.cpu.sp];
    z80.cpu.sp += 1;
}


