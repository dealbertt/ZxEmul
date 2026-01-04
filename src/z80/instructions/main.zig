const std = @import("std");

const print = std.debug.print;
const s = @import("../internals/state.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

//TODO
//- implement the missing flag handles on ops like inc, dec, add, sub, etc,...

//KEEP IN MIND THAT THE Z80 IS LITTLE ENDIAN
//We declare and initialize the registers to 0
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'

//function to load the specified program, idk if its going to be throught a command line- argument

//gotta make a couple of optimizations for the first instructions like ld to use a template

fn add_16bitRegs(reg1: u16, reg2: u16, state: *s.State) u16 {
    const sum = @addWithOverflow(reg1, reg2);
    if (sum[1] == 1) {
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }

    if(sum[0] == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N); 
    return sum[0];
}

fn inc_8bitReg(reg: *u8, state: *s.State) void{
    const inc = @addWithOverflow(reg.*, 1);
    if(inc[1] == 1){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }

    if(inc[0] == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }


    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);
    reg.* = inc[0];
}

fn inc_16bitReg(reg: *u16, state: *s.State) void{
    const inc = @addWithOverflow(reg.*, 1);
    if(inc[1] == 1){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;

    }

    if(inc[0] == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }


    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);
    reg.* = inc[0];
}

const Register = enum(u3){
    B, C, D, E, H, L, A, HL,
};

const RegisterPair = enum(u3){
    BC, DE, HL, AF,
};

fn getRegisterValue(r: Register, state: *s.State) u8{
    return switch(r){
        .B => state.bc.bytes.hi,
        .C => state.bc.bytes.lo,
        .D => state.de.bytes.hi,
        .E => state.de.bytes.lo,
        .H => state.hl.bytes.hi,
        .L => state.hl.bytes.lo,
        .A => state.af.bytes.hi,
        .HL=> state.memory[state.hl.pair]
    };
}

fn getRegisterPair(rp: RegisterPair, state: *s.State) *s.regPair {
    return switch(rp){
        .BC => &state.bc,
        .DE => &state.de,
        .HL => &state.hl,
        .AF => &state.af,
    };
}
fn setRegisterValue(r: Register, value: u8, state: *s.State) void {
    switch(r){
        .B => state.bc.bytes.hi = value,
        .C => state.bc.bytes.lo = value,
        .D => state.de.bytes.hi = value,
        .E => state.de.bytes.lo = value,
        .H => state.hl.bytes.hi = value,
        .L => state.hl.bytes.lo = value,
        .A => state.af.bytes.hi = value,
        .HL=> state.memory[state.hl.pair] = value,
    }
}


//pub fn add_offset(reg: u16, offset: i8) u16{
//return 0;
//}

//Opcode 00
//No operation is performed.
pub fn op_nop(state: *s.State) void {
    _ = state;
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
pub fn op_unknown(state: *s.State) void {
    _ = state;
    print("Unknown opcode {}", .{s.opcode});
}
pub fn op_ld_bc_nn(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.pc += 2;
    state.bc.pair = nn;
}

//Opcode 02
pub fn op_ld_bc_addr_a(state: *s.State) void {
    state.memory[state.bc.pair] = state.af.bytes.hi;
}

//Opcode 03
pub fn op_inc_bc(state: *s.State) void {
    inc_16bitReg(&state.bc.pair, state);
}

//Opcode 04
pub fn op_inc_b(state: *s.State) void {
    inc_8bitReg(&state.bc.bytes.hi, state);
}

//Opcode 05
pub fn op_dec_b(state: *s.State) void {
    state.bc.bytes.hi -= 1;
}

//Opcode 06
pub fn op_ld_b_n(state: *s.State) void {
    state.bc.bytes.hi = state.memory[state.pc];
    state.pc += 1;
}

//Opcode 07
pub fn op_rlca(state: *s.State) void {
    //1111 1110
    //LSB: Least significant bit
    //Extract the bit 7, and set it in the LSB, given that its going to be
    //copied into the LSB of A and F.
    const bit7: u8 = (state.af.bytes.hi >> 7) & 1;
    //0000 0001

    //Once we have that, we set A, to the contents of A
    //shifted 1 bit to the left or bit7 -> a circular rotation
    //because bit0 now has the contents of bit 7
    //
    //Reset the N and H flag
    state.af.bytes.hi = ((state.af.bytes.hi << 1) | bit7) & 0xFF;
    //because we shift to the left, zig might promote to a bigger value, but we only
    //want to keep the lowest 8 bits
    //this is basically a NOT of s.FLAG_C or FLAG_N or FLAG_H
    //0000 0001]
    //OR       ] -> 0000 0011]
    //0000 0010]        OR   ] -> 0001 0011
    //                              NOT
    //OR       ] -> 0001 0000]    1110 1100
    //0001 0000]
    //
    //this basically means that no matter the value, it will reset those flags to 0
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    //even tho its not necessary, we also reset flag C, because it will be set
    //to the value of bit7 of A
    state.af.bytes.lo |= bit7;
}

//Opcode 08
pub fn op_ex_af_af_shadow(state: *s.State) void {
    _ = state;
}

//Opcode 09
pub fn op_add_hl_bc(state: *s.State) void {
    state.hl.pair += state.bc.pair;
}

//Opcode 0A
pub fn op_ld_a_bc_addr(state: *s.State) void {
    state.af.bytes.hi = state.memory[state.hl.pair];
}

//Opcode 0B
pub fn op_dec_bc(state: *s.State) void {
    state.bc.pair += 1;
}

//Opcode 0C
pub fn op_inc_c(state: *s.State) void {
    inc_8bitReg(&state.bc.bytes.lo, state);
}

//Opcode 0D
pub fn op_dec_c(state: *s.State) void {
    state.bc.bytes.lo -= 1;
}

//Opcode 0E
pub fn op_ld_c_n(state: *s.State) void {
    state.bc.bytes.lo = state.memory[state.pc];
    state.pc += 1;
}

//Opcoe 0F
pub fn op_rrca(state: *s.State) void {
    const bit7: u8 = (state.af.bytes.hi >> 7) & 1;

    state.af.bytes.hi = ((state.af.bytes.hi >> 1) | bit7) & 0xFF;
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    state.af.bytes.lo |= bit7;
}

//Opcode 10
//THIS FUNCTIONS NEEDS A LOT OF TESTING
pub fn op_djnz_d(state: *s.State) void {

    //this when
    //
    state.bc.bytes.hi -%= 1;
    if (state.bc.bytes.hi != 0) {
        //We want to take the 16bit pc(u16), add a signed 8bit offset,
        //and store it back as a u16
        const offset: i8 = @bitCast(state.memory[state.pc]);
        //state.pc = @intCast(u16, @as(i16, state.pc) + @as(i16, offset));
        const new_pc = @as(i16, @bitCast(state.pc)) + @as(i16, offset);
        //state.pc = @as(u16, @intCast(@as(i16, state.pc) + @as(i16, offset)));
        state.pc = @bitCast(@as(i16, new_pc));
    }
}

//Opcode 11
pub fn op_ld_de_nn(state: *s.State) void {
    //the pc has been incremented, meaning that i am going to get the high bytes of nn
    const nn: u16 = mem.read16(state, state.pc);
    state.pc += 2;
    state.de.pair = nn;
}

//Opcode 12
pub fn op_ld_a_de_addr(state: *s.State) void {
    state.memory[state.de.pair] = state.af.bytes.hi;
}

//Opcode 13
pub fn op_inc_de(state: *s.State) void {
    inc_16bitReg(&state.de.pair, state);
}

//Opcode 14
pub fn op_inc_d(state: *s.State) void {
    inc_8bitReg(&state.de.bytes.hi, state);
}

//Opcode 15
pub fn op_dec_d(state: *s.State) void {
    state.de.bytes.hi -= 1;
}

//Opcode 16
pub fn op_ld_d_n(state: *s.State) void {
    state.de.bytes.hi = state.memory[state.pc];
    state.pc += 1;
}

//Opcode 17
//The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
pub fn rla(state: *s.State) void {
    const bit7: u8 = (state.af.bytes.hi >> 7) & 1;
    const prevCarry: u8 = state.af.bytes.lo & 0x01; //get the last bit -> carry flag

    state.af.bytes.hi = ((state.af.bytes.hi << 1) | bit7) & 0xFF;
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= bit7;

    //The previous contents of the Carry flag are copied to bit 0
    state.af.bytes.hi |= prevCarry;
}

pub fn jr_d(state: *s.State) void {
    const jump: i8 = @bitCast(state.memory[state.pc]);
    const new_pc: i16 = @as(i16, @bitCast(state.pc)) + @as(i16, jump);

    state.pc = @bitCast(@as(i16, new_pc));
}

pub fn op_add_hl_de(state: *s.State) void {
    state.hl.pair = add_16bitRegs(state.hl.pair, state.de.pair, state);
}

pub fn op_ld_de_addr_a(state: *s.State) void {
    state.af.bytes.hi = state.memory[state.de.pair];
}

pub fn op_dec_de(state: *s.State) void {
    state.de.pair -= 1;
}

pub fn op_inc_e(state: *s.State) void {
    inc_8bitReg(&state.de.bytes.lo, state);
}

pub fn op_dec_e(state: *s.State) void {
    state.de.bytes.lo -= 1;
}
pub fn op_ld_e_n(state: *s.State) void {
    state.de.bytes.lo = state.memory[state.pc];
    state.pc += 1;
}

pub fn op_rra(state: *s.State) void {
    const bit7: u8 = (state.af.bytes.hi >> 7) & 1;
    const prevCarry: u8 = state.af.bytes.lo & 0x01; //get the last bit -> carry flag

    state.af.bytes.hi = ((state.af.bytes.hi >> 1) | bit7) & 0xFF;
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= bit7;

    //The previous contents of the Carry flag are copied to bit 0
    state.af.bytes.hi |= prevCarry;
}

pub fn op_jr_nz(state: *s.State) void {
    if ((state.af.bytes.lo & s.FLAG_Z) == 0) {
        //zero flag is not set
        const jump: i8 = @bitCast(state.memory[state.pc]);
        const new_pc: i16 = @as(i16, @bitCast(state.pc)) + @as(i16, jump);

        state.pc = @bitCast(@as(i16, new_pc));
    }
}

pub fn op_ld_hl_nn(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.hl.pair = nn;

    state.pc += 2;
}

pub fn op_ld_nn_addr_hl(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.memory[nn] = state.hl.bytes.lo;
    state.memory[nn + 1] = state.hl.bytes.hi;

    state.pc += 2;
}

pub fn op_inc_hl(state: *s.State) void {
    inc_16bitReg(&state.hl.pair, state);
}

pub fn op_inc_h(state: *s.State) void {
    inc_8bitReg(&state.hl.bytes.hi, state);
}

pub fn op_dec_h(state: *s.State) void {
    state.hl.bytes.hi -= 1;
}

pub fn op_ld_h_n(state: *s.State) void {
    state.hl.bytes.hi = state.memory[state.pc];
    state.pc += 1;
}

pub fn op_daa(state: *s.State) void {
    _ = state;
}

pub fn op_jr_z(state: *s.State) void {
    if ((state.af.bytes.lo & s.FLAG_Z) != 0) {
        //zero flag is not set
        const jump: i8 = @bitCast(state.memory[state.pc]);
        const new_pc: i16 = @as(i16, @bitCast(state.pc)) + @as(i16, jump);

        state.pc = @bitCast(@as(i16, new_pc));
        state.pc += 1;
    }
}

pub fn op_add_hl_hl(state: *s.State) void {
    state.hl.pair += state.hl.pair;
}

//1 byte for the s.opcode?
//1 byte for
pub fn op_ld_hl_nn_addr(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.hl.bytes.lo = state.memory[nn];
    state.hl.bytes.hi = state.memory[nn + 1];

    state.pc += 2;
}

pub fn op_dec_hl(state: *s.State) void {
    state.hl.pair -= 1;
}

pub fn op_inc_l(state: *s.State) void {
    inc_8bitReg(&state.hl.bytes.lo, state);
}

pub fn op_dec_l(state: *s.State) void {
    state.hl.bytes.lo -= 1;
}

pub fn op_ld_l_n(state: *s.State) void {
    state.hl.bytes.lo = state.memory[state.pc];
}

pub fn op_cpl(state: *s.State) void {
    state.af.bytes.hi = ~state.af.bytes.hi;

    //Set the H and N flags
    state.af.bytes.lo |= (s.FLAG_H | s.FLAG_C);
}

pub fn op_jr_nc(state: *s.State) void {
    if ((state.af.bytes.lo & s.FLAG_C) == 0) {
        //Carry flag is not set
        const jump: i8 = @bitCast(state.memory[state.pc]);
        const new_pc: i16 = @as(i16, @bitCast(state.pc)) + @as(i16, jump);

        state.pc = @bitCast(@as(i16, new_pc));
        state.pc += 1;
    }
}

pub fn op_ld_sp_nn(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.sp = nn;

    state.pc += 2;
}

pub fn op_ld_nn_addr_a(state: *s.State) void {
    const nn = mem.read16(state, state.pc);

    state.memory[nn] = state.af.bytes.hi;

    state.pc += 2;
}

pub fn op_inc_sp(state: *s.State) void {
    state.sp += 1;
}

pub fn op_inc_hl_addr(state: *s.State) void {
    //state.memory[state.hl.pair] += 1;
    inc_8bitReg(&state.memory[state.hl.pair], state);
}

pub fn op_dec_hl_addr(state: *s.State) void {
    state.memory[state.hl.pair] -= 1;
}

pub fn op_ld_hl_addr_n(state: *s.State) void {
    state.memory[state.hl.pair] = state.memory[state.pc];
}

pub fn op_scf(state: *s.State) void {
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= s.FLAG_C;
}

pub fn op_jr_c(state: *s.State) void {
    if ((state.af.bytes.lo & s.FLAG_C) != 0) {
        //Carry flag is set
        const jump: i8 = @bitCast(state.memory[state.pc]);
        const new_pc: i16 = @as(i16, @bitCast(state.pc)) + @as(i16, jump);

        state.pc = @bitCast(@as(i16, new_pc));
        state.pc += 1;
    }
}

pub fn op_add_hl_sp(state: *s.State) void {
    state.hl.pair += state.sp;
}

pub fn op_ld_a_nn_addr(state: *s.State) void {
    const nn = mem.read16(state, state.pc);
    state.af.bytes.hi = state.memory[nn];

    state.pc += 2;
}

pub fn op_dec_sp(state: *s.State) void {
    state.sp -= 1;
}

pub fn op_inc_a(state: *s.State) void {
    inc_8bitReg(&state.af.bytes.hi, state);
}

pub fn op_dec_a(state: *s.State) void {
    state.af.bytes.hi -= 1;
}

pub fn op_ld_a_n(state: *s.State) void {
    state.af.bytes.hi = state.memory[state.pc];
    state.pc += 1;
}

pub fn op_ccf(state: *s.State) void {
    state.af.bytes.lo ^= s.FLAG_C;
}

fn op_ld(src: Register, dst: Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    setRegisterValue(dst, value, state);
}

pub fn decode_ld(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b111);
    const dst: Register = @enumFromInt((s.opcode >> 3) & 0b111);
    op_ld(src, dst, state);
}

fn op_add_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = add_a_value(value, state);
}

pub fn decode_add_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_add_a(src, state);
}

fn add_a_value(value: u8, state: *s.State) u8{
    const add:u16 = @as(u16, state.af.bytes.hi) + @as(u16, value);    

    const res: u8 = @truncate(add);


    if(res < 0){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }

    if(res == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        state.af.bytes.lo |= s.FLAG_S;
    }
    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);

    return res;
}

fn op_adc_a(src: Register, state: *s.State) void {
    var value: u8 = getRegisterValue(src, state);
    value += (state.af.bytes.lo & s.FLAG_C);
    state.af.bytes.hi = adc_a_value(value, state);
}

pub fn decode_adc_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_adc_a(src, state);
}

fn adc_a_value(value: u8, state: *s.State) u8{
    const carry = (state.af.bytes.lo & s.FLAG_C);
    const sum = @as(u16, value) + @as(u16, state.af.bytes.hi) + carry;

    const res: u8 = @truncate(sum);

    if(sum > 0xFF){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }
    
    if(res == 0){
        //set the zero flag if result is 0 
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        state.af.bytes.lo |= s.FLAG_S;
    }

    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);

    return res;
}

fn op_sub_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = sub_a_value(value, state);
}

pub fn decode_sub_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_sub_a(src, state);
}

fn sub_a_value(value: u8, state: *s.State) u8{
    const sub:u16 = @as(u16, state.af.bytes.hi) - @as(u16, value);    

    const res: u8 = @truncate(sub);


    if(res < 0){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }

    if(res == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        state.af.bytes.lo |= s.FLAG_S;
    }
    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);

    return res;
}

fn op_sbc_a(src: Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    value += (state.af.bytes.lo & s.FLAG_C);
    state.af.bytes.hi = sbc_a_value(value);
    
}

pub fn decode_sbc_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_sbc_a(src, state);
}

fn sbc_a_value(value: u8, state: *s.State) u8{
    const carry = (state.af.bytes.lo & s.FLAG_C);
    const sum = @as(u16, value) - @as(u16, state.af.bytes.hi) - carry;

    const res: u8 = @truncate(sum);

    //flags
    //carry flag
    if(sum > 0xFF){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }
    
    //zero flag
    if(res == 0){
        //set the zero flag if result is 0 
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //sign flag
    if((res & 0x80) != 0){
        //set the sign flag
        state.af.bytes.lo |= s.FLAG_S;
    }

    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);

    return res;
}

const op = enum {
    And,
    Xor,
    Or
};

fn decode_binary_operation(value: u8, operation: op, state: *s.State) u8 {
        var res: u8 = state.af.bytes.hi;
        switch(operation){
            .And => res &= value,
            .Xor => res ^= value,
            .Or  => res |= value,
        }

        //reset the N flag
        state.af.bytes.lo &= ~(s.FLAG_N);

        //reset the C flag
        state.af.bytes.lo &= ~(s.FLAG_C);

        return res;
}

fn op_and_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .And, state);
}

pub fn decode_and_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_and_a(src, state);
}

fn op_xor_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .Xor, state);
}

pub fn decode_xor_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_xor_a(src, state);
}


fn op_or_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .Or, state);
}

pub fn decode_or_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_xor_a(src, state);
}


fn op_cp_a(src:Register, state: *s.State) void {
    const value = getRegisterValue(src, state);
    state.af.bytes.hi = cp_a_value(value, state);
}

pub fn decode_cp_a(state: *s.State) void {
    const src: Register = @enumFromInt(s.opcode & 0b1111);
    op_cp_a(src, state);
}

fn cp_a_value(value: u8, state: *s.State) u8 {
    const sub:u16 = @as(u16, state.af.bytes.hi) - @as(u16, value);    

    const res: u8 = @truncate(sub);

    return res;
}


pub fn ret_nz(state: *s.State) void {
    if((state.af.bytes.lo & s.FLAG_Z) == 0){
        //pop  
        const lo = state.memory[state.sp];
        state.sp += 1;

        const hi = state.memory[state.sp];
        state.sp += 1;

        state.pc = @as(u16, hi) << 8 | lo;
    }
}

fn op_pop_reg(src:RegisterPair, state: *s.State) void {
    const pair = getRegisterPair(src, state);
    pop_reg(pair, state);
}

pub fn decode_pop_reg(state: *s.State) void {
    const src: RegisterPair = @enumFromInt(@as(u3, @intCast((s.opcode >> 4) & 0b11)));
    op_pop_reg(src, state);
}

fn pop_reg(regPair: *s.regPair, state: *s.State) void {
    regPair.bytes.lo = state.memory[state.sp];
    state.sp += 1;

    regPair.bytes.hi = state.memory[state.sp];
    state.sp += 1;
}


