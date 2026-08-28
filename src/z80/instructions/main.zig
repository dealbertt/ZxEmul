const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

//TODO
//- implement the missing flag handles on ops like inc, dec, add, sub, etc,...
//- Fix enums

//KEEP IN MIND THAT THE Z80 IS LITTLE ENDIAN
//One set is called BC, DE, and HL while the complementary set is called BC', DE', and HL'


//gotta make a couple of optimizations for the first instructions like ld to use a template

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
    std.debug.print("Unknown opcode {}", .{state.opcode});
}
//possible opcodes for this kind of instructions are
//01
//11
//21
//31
//the only difference between all of these is the first digit
//all of these instructions are 3 bytes, 1 for the opcode and 2 for the nn
//so we have to extract the first digit of the first byte? and then cast it

pub fn decode_ld_16reg_nn(state: *s.State) void {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    
    const regs = h.get16BitRegister(src, state);
    const nn = mem.read16(state, &state.pc);
    ld_16reg_nn(regs, nn);
}

fn ld_16reg_nn(regs: *u16, value: u16) void {
    regs.* = value;
}

//Opcode 02
pub fn op_ld_bc_addr_a(state: *s.State) void {
    state.memory[state.bc.pair] = state.af.bytes.hi;
}

//Opcode 03
pub fn decode_inc_16reg(state: *s.State) void {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const regs = h.get16BitRegister(src, state);
    
    h.inc_16bitReg(regs, state);
}

pub fn decode_inc_8reg(state: *s.State) void {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    h.inc_8bitReg(reg, state);
}

//Opcode 05
pub fn decode_dec_8reg(state: *s.State) void {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    h.dec_8bitReg(reg, state);
}

pub fn decode_dec_16reg(state: *s.State) void {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state); 
    
    h.dec_16bitReg(reg, state);
}


//Opcodes 06, 0E, 16, 1E, 26, 2E, 36, 3E (LD r,n)
pub fn decode_ld_reg_n(state: *s.State) void {
    const dst: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const value = mem.read8(state, &state.pc);
    h.setRegisterValue(dst, value, state);
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
    state.hl.pair = h.add_16bitRegs(state.hl.pair, state.bc.pair, state);
}

//Opcode 0A
pub fn op_ld_a_bc_addr(state: *s.State) void {
    state.af.bytes.hi = state.memory[state.bc.pair];
}

//Opcoe 0F
pub fn op_rrca(state: *s.State) void {
    const bit0: u8 = state.af.bytes.hi & 1;

    state.af.bytes.hi = (state.af.bytes.hi >> 1) | (bit0 << 7);
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    state.af.bytes.lo |= bit0;
}

//Opcode 10
pub fn op_djnz_d(state: *s.State) void {
    state.bc.bytes.hi -%= 1;

    //the displacement byte is always consumed, whether the jump is taken or not
    const offset: i8 = @bitCast(mem.read8(state, &state.pc));

    if (state.bc.bytes.hi != 0) {
        //We want to take the 16bit pc(u16), add a signed 8bit offset,
        //and store it back as a u16
        const new_pc = @as(i16, @bitCast(state.pc)) + @as(i16, offset);
        state.pc = @bitCast(new_pc);
    }
}

//Opcode 12
pub fn op_ld_de_addr_a(state: *s.State) void {
    state.memory[state.de.pair] = state.af.bytes.hi;
}

//Opcode 17
//The contents of A are rotated left one bit position. Bit 7 is copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
pub fn rla(state: *s.State) void {
    const bit7: u8 = (state.af.bytes.hi >> 7) & 1;
    const prevCarry: u8 = state.af.bytes.lo & s.FLAG_C;

    state.af.bytes.hi = (state.af.bytes.hi << 1) | prevCarry;
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= bit7;
}

//shared by all JR/DJNZ instructions: the displacement byte is always consumed
fn jr_offset(state: *s.State) i8 {
    return @bitCast(mem.read8(state, &state.pc));
}

//Opcode 18
pub fn jr_d(state: *s.State) void {
    const jump = jr_offset(state);
    state.pc = @bitCast(@as(i16, @bitCast(state.pc)) + @as(i16, jump));
}

//Opcode 19
pub fn op_add_hl_de(state: *s.State) void {
    state.hl.pair = h.add_16bitRegs(state.hl.pair, state.de.pair, state);
}

//Opcode 1A
pub fn op_ld_a_de_addr(state: *s.State) void {
    state.af.bytes.hi = state.memory[state.de.pair];
}

//Opcode 1F
pub fn op_rra(state: *s.State) void {
    const bit0: u8 = state.af.bytes.hi & 1;
    const prevCarry: u8 = state.af.bytes.lo & s.FLAG_C;

    state.af.bytes.hi = (state.af.bytes.hi >> 1) | (prevCarry << 7);
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= bit0;
}

//Opcode 20
pub fn op_jr_nz(state: *s.State) void {
    const jump = jr_offset(state);
    if ((state.af.bytes.lo & s.FLAG_Z) == 0) {
        state.pc = @bitCast(@as(i16, @bitCast(state.pc)) + @as(i16, jump));
    }
}

//Opcode 22
pub fn op_ld_nn_addr_hl(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);
    state.memory[nn] = state.hl.bytes.lo;
    state.memory[nn + 1] = state.hl.bytes.hi;
}

//Opcode 27
pub fn op_daa(state: *s.State) void {
    _ = state;
}


//Opcode 28
pub fn op_jr_z(state: *s.State) void {
    const jump = jr_offset(state);
    if ((state.af.bytes.lo & s.FLAG_Z) != 0) {
        state.pc = @bitCast(@as(i16, @bitCast(state.pc)) + @as(i16, jump));
    }
}

//Opcode 29
pub fn op_add_hl_hl(state: *s.State) void {
    state.hl.pair = h.add_16bitRegs(state.hl.pair, state.hl.pair, state);
}

//Opcode 2A
pub fn op_ld_hl_nn_addr(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);
    state.hl.bytes.lo = state.memory[nn];
    state.hl.bytes.hi = state.memory[nn + 1];
}

//Opcode 2F
pub fn op_cpl(state: *s.State) void {
    state.af.bytes.hi = ~state.af.bytes.hi;

    //Set the H and N flags
    state.af.bytes.lo |= (s.FLAG_H | s.FLAG_N);
}

//Opcode 30
pub fn op_jr_nc(state: *s.State) void {
    const jump = jr_offset(state);
    if ((state.af.bytes.lo & s.FLAG_C) == 0) {
        state.pc = @bitCast(@as(i16, @bitCast(state.pc)) + @as(i16, jump));
    }
}

//Opcode 32
pub fn op_ld_nn_addr_a(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);
    state.memory[nn] = state.af.bytes.hi;
}

//Opcode 37
pub fn op_scf(state: *s.State) void {
    //reset
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    //set
    state.af.bytes.lo |= s.FLAG_C;
}

//Opcode 38
pub fn op_jr_c(state: *s.State) void {
    const jump = jr_offset(state);
    if ((state.af.bytes.lo & s.FLAG_C) != 0) {
        state.pc = @bitCast(@as(i16, @bitCast(state.pc)) + @as(i16, jump));
    }
}

//Opcode 39
pub fn op_add_hl_sp(state: *s.State) void {
    state.hl.pair = h.add_16bitRegs(state.hl.pair, state.sp, state);
}

//Opcode 3A
pub fn op_ld_a_nn_addr(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);
    state.af.bytes.hi = state.memory[nn];
}

//Opcode 3F
pub fn op_ccf(state: *s.State) void {
    const oldCarry = state.af.bytes.lo & s.FLAG_C;
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= if (oldCarry != 0) s.FLAG_H else s.FLAG_C;
}

//Opcode 40-7F
fn op_ld(src: h.Register, dst: h.Register, state: *s.State) void {
    const value = h.getRegisterValue(src, state);
    h.setRegisterValue(dst, value, state);
}

pub fn decode_ld(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    const dst: h.Register = @enumFromInt((state.opcode >> 3) & 0b111);
    op_ld(src, dst, state);
}


pub fn op_halt(state: *s.State) void {
    _ = state;
}

//Opcode 80-87
fn op_add_a(src:h.Register, state: *s.State) void {
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = add_a_value(value, state);
}

pub fn decode_add_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    op_add_a(src, state);
}

fn add_a_value(value: u8, state: *s.State) u8{
    const add:u16 = @as(u16, state.af.bytes.hi) + @as(u16, value);

    const res: u8 = @truncate(add);


    if(add > 0xFF){
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

//Opcode 88-8F
fn op_adc_a(src: h.Register, state: *s.State) void {
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = adc_a_value(value, state);
}

pub fn decode_adc_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
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

//Opcode 90-97
fn op_sub_a(src:h.Register, state: *s.State) void {
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = sub_a_value(value, state);
}

pub fn decode_sub_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    op_sub_a(src, state);
}

fn sub_a_value(value: u8, state: *s.State) u8{
    const a = state.af.bytes.hi;
    const res: u8 = a -% value;

    if(value > a){
        //set the carry flag if a borrow happened
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
    //set the N flag
    state.af.bytes.lo |= s.FLAG_N;

    return res;
}

//Opcode 98-9F
fn op_sbc_a(src: h.Register, state: *s.State) void {
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = sbc_a_value(value, state);
}

pub fn decode_sbc_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    op_sbc_a(src, state);
}

fn sbc_a_value(value: u8, state: *s.State) u8{
    const carry: u8 = state.af.bytes.lo & s.FLAG_C;
    const a = state.af.bytes.hi;
    const res: u8 = a -% value -% carry;

    //carry flag: a borrow happened if value+carry could not be covered by a
    if(@as(u16, value) + @as(u16, carry) > @as(u16, a)){
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

    //set the N flag
    state.af.bytes.lo |= s.FLAG_N;

    return res;
}


fn decode_binary_operation(value: u8, operation: h.op, state: *s.State) u8 {
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

        if(res == 0){
            //set the zero flag
            state.af.bytes.lo |= s.FLAG_Z;
        }

        //sign flag
        if((res & 0x80) != 0){
            //set the sign flag
            state.af.bytes.lo |= s.FLAG_S;
        }

        return res;
}

//Opcode A0-A7
pub fn decode_and_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .And, state);
}

//Opcode A8-AF
pub fn decode_xor_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .Xor, state);
}


//Opcode B0-B7
pub fn decode_or_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    const value = h.getRegisterValue(src, state);
    state.af.bytes.hi = decode_binary_operation(value, .Or, state);
}


//Opcode B8-BF
//CP compares A with the operand (like SUB) but discards the result, leaving A unchanged
pub fn decode_cp_a(state: *s.State) void {
    const src: h.Register = @enumFromInt(state.opcode & 0b111);
    const value = h.getRegisterValue(src, state);
    _ = sub_a_value(value, state);
}

//Opcode C0, D0, E0, F0, C8, D8, E8, F8
pub fn decode_ret_condition_nn(state: *s.State) void {
    const cond: h.Condition = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    ret_condition_nn(cond, state);
}

pub fn ret_condition_nn(cond: h.Condition, state: *s.State) void {
    if(h.conditionMet(cond, state)){
        //pop
        const lo = state.memory[state.sp];
        state.sp +%= 1;

        const hi = state.memory[state.sp];
        state.sp +%= 1;

        state.pc = @as(u16, hi) << 8 | lo;
    }
}

//Opcode C1, D1, E1, F1
pub fn decode_pop_reg(state: *s.State) void {
    const src: h.RegisterPair = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const pair = h.getRegisterPair(src, state);
    pop_reg(pair, state);
}


fn pop_reg(regPair: *s.regPair, state: *s.State) void {
    regPair.bytes.lo = state.memory[state.sp];
    state.sp +%= 1;

    regPair.bytes.hi = state.memory[state.sp];
    state.sp +%= 1;
}


//Opcode C2, D2, E2, F2, CA, DA, EA, FA
pub fn decode_jp_condition_nn(state: *s.State) void {
    const cond: h.Condition = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const nn = mem.read16(state, &state.pc);

    jp_condition_nn(cond, nn, state);
}

fn jp_condition_nn(cond: h.Condition, value: u16, state: *s.State) void {
    if(h.conditionMet(cond, state)){
        state.pc = value;
    }
}

//Opcode C3
pub fn op_jp_nn(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);

    state.pc = nn;
}


//Opcode C4, D4, E4, F4, CC, DC, EC, FC
pub fn decode_call_condition_nn(state: *s.State) void {
    const cond: h.Condition = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const nn = mem.read16(state, &state.pc);

    call_condition_nn(cond, nn, state);
}


//you fetch the byte for the instruction itself, and then 2 for nn
fn call_condition_nn(cond: h.Condition, value: u16, state: *s.State) void {
    if(h.conditionMet(cond, state)){
        h.push16BitValue(state.pc, state);
        state.pc = value;
    }
}

//Opcode CD
pub fn op_call_nn(state: *s.State) void {
    const nn = mem.read16(state, &state.pc);

    h.push16BitValue(state.pc, state);
    state.pc = nn;
}

//Opcode C5, D5, E5, F5
pub fn decode_push_reg(state: *s.State) void {
    const src: h.RegisterPair = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const pair = h.getRegisterPair(src, state);
    h.push16BitValue(pair.pair, state);
}

pub fn decode_add_a_n(state: *s.State) void {
    const value = mem.read8(state, &state.pc);

    state.af.bytes.hi = add_a_value(value, state);
}

pub fn decode_sub_n(state: *s.State) void {
    const value = mem.read8(state, &state.pc);

    state.af.bytes.hi = sub_a_value(value, state);
}

pub fn decode_rst_value_h(state: *s.State) void {
    //get value for what has to be loaded in pc after pushing
    const vector = h.getTargetAddress(state.opcode);
    op_rst_nn_h(vector, state);
}

pub fn op_rst_nn_h(vector: u8, state: *s.State) void {
    h.push16BitValue(state.pc, state);
    state.pc = vector;
}

pub fn op_ret(state: *s.State) void {
    //moved to the low-order 8 bits of the pc
    //resets the low byte and loads the first part
    const low: u16 = state.memory[state.sp];
    state.sp +%= 1;

    const high: u16 = state.memory[state.sp];
    state.sp +%= 1;

    //moved to the high-order 8 bits of the pc
    //resets the high byte and loads the second part, shifting it 8 bits to the left to not overwrite the previously loaded value
    state.pc = (high << 8) | low;
}

pub fn op_jp_hl(state: *s.State) void {
    state.pc = state.hl.pair;
}


pub fn op_ex_de_hl(state: *s.State) void {
        state.de.pair = state.de.pair ^ state.hl.pair;
        state.hl.pair = state.de.pair ^ state.hl.pair;
        state.de.pair = state.de.pair ^ state.hl.pair;
}

//Opcode E3
pub fn op_ex_sp_addr_hl(state: *s.State) void {
    const lo = state.memory[state.sp];
    const hi = state.memory[state.sp +% 1];

    state.memory[state.sp] = state.hl.bytes.lo;
    state.memory[state.sp +% 1] = state.hl.bytes.hi;

    state.hl.bytes.lo = lo;
    state.hl.bytes.hi = hi;
}

//Opcode F9
pub fn op_ld_sp_hl(state: *s.State) void {
    state.sp = state.hl.pair;
}

pub fn op_adc_a_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);
    state.af.bytes.hi = adc_a_value(n, state);
}

pub fn op_and_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);
    state.af.bytes.hi = decode_binary_operation(n, .And, state);
}

pub fn op_xor_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);
    state.af.bytes.hi = decode_binary_operation(n, .Xor, state);
}

pub fn op_or_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);
    state.af.bytes.hi = decode_binary_operation(n, .Or, state);
}

pub fn op_sbc_a_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);

    state.af.bytes.hi = sbc_a_value(n, state);
}

//CP compares A with n (like SUB) but discards the result, leaving A unchanged
pub fn op_cp_n(state: *s.State) void {
    const n = mem.read8(state, &state.pc);

    _ = sub_a_value(n, state);
}


