const s = @import("../internals/state.zig");

pub const Register = enum(u3){
    B, C, D, E, H, L, HL, A,
};

pub const RegisterPair = enum(u3){
    BC, DE, HL, AF
};

pub const Reg16Bit = enum(u3) {
    BC, DE, HL, SP, IX, IY
};

pub const Condition = enum(u3){
    NZ, Z,
    NC, C,
    PO, PE,
    P, M,
};

pub const op = enum {
    And,
    Xor,
    Or
};

pub const IndexBase = enum{
    HL, IX, IY
};

pub fn indexedAddresses(state: *s.State, base: IndexBase, d: i8) u16 {
    const offset: u16 = @bitCast(@as(i16,d));
    return switch (base) {
        .HL => state.hl.pair,
        .IX => state.ix +% offset,
        .IY => state.iy +% offset,
    };
}

//sets the given flag when condition is true, resets it otherwise
pub fn setFlag(state: *s.State, flag: u8, condition: bool) void {
    if(condition){
        state.af.bytes.lo |= flag;
    }else{
        state.af.bytes.lo &= ~flag;
    }
}

//S and Z come straight from the 8-bit result for almost every arithmetic/logic instruction
fn setSignZeroFlags(state: *s.State, result: u8) void {
    setFlag(state, s.FLAG_S, (result & 0x80) != 0);
    setFlag(state, s.FLAG_Z, result == 0);
}

//signed overflow on an 8-bit addition: both operands had the same sign and the result's sign differs
fn addOverflow(a: u8, value: u8, result: u8) bool {
    return ((a ^ result) & (value ^ result) & 0x80) != 0;
}

//signed overflow on an 8-bit subtraction: the operands had different signs and the result's sign differs from a
fn subOverflow(a: u8, value: u8, result: u8) bool {
    return ((a ^ value) & (a ^ result) & 0x80) != 0;
}

//ADD HL,rr / ADD IX,rr / ADD IY,rr: only H, N and C change, S, Z and P/V are left untouched
pub fn add_16bitRegs(reg1: u16, reg2: u16, state: *s.State) u16 {
    const sum = @addWithOverflow(reg1, reg2);

    //H is the carry out of bit 11 (the half carry of the high byte)
    setFlag(state, s.FLAG_H, (reg1 & 0x0FFF) + (reg2 & 0x0FFF) > 0x0FFF);
    setFlag(state, s.FLAG_C, sum[1] == 1);
    state.af.bytes.lo &= ~s.FLAG_N;
    return sum[0];
}

//ADC HL,rr: a + value + carry on 16 bits. unlike ADD HL,rr, every flag is affected,
//and S, Z and P/V are computed on the full 16-bit result
pub fn adc_16bit(a: u16, value: u16, state: *s.State) u16 {
    const carry_in: u16 = state.af.bytes.lo & s.FLAG_C;
    const sum: u32 = @as(u32, a) + value + carry_in;
    const res: u16 = @truncate(sum);

    setFlag(state, s.FLAG_S, (res & 0x8000) != 0);
    setFlag(state, s.FLAG_Z, res == 0);
    //H is the carry out of bit 11 (the half carry of the high byte)
    setFlag(state, s.FLAG_H, (a & 0x0FFF) + (value & 0x0FFF) + carry_in > 0x0FFF);
    //P/V: both operands had the same sign and the result's sign differs
    setFlag(state, s.FLAG_P, ((a ^ res) & (value ^ res) & 0x8000) != 0);
    setFlag(state, s.FLAG_C, sum > 0xFFFF);
    state.af.bytes.lo &= ~s.FLAG_N;

    return res;
}

//SBC HL,rr: a - value - carry on 16 bits, every flag is affected.
//takes values rather than pointers, so SBC HL,HL reads HL before anything is written
pub fn sbc_16bit(a: u16, value: u16, state: *s.State) u16 {
    const borrow_in: u16 = state.af.bytes.lo & s.FLAG_C;
    const res: u16 = a -% value -% borrow_in;

    setFlag(state, s.FLAG_S, (res & 0x8000) != 0);
    setFlag(state, s.FLAG_Z, res == 0);
    //H is set on a borrow from bit 12
    setFlag(state, s.FLAG_H, (a & 0x0FFF) < (value & 0x0FFF) + borrow_in);
    //P/V: the operands had different signs and the result's sign differs from a
    setFlag(state, s.FLAG_P, ((a ^ value) & (a ^ res) & 0x8000) != 0);
    setFlag(state, s.FLAG_C, @as(u32, a) < @as(u32, value) + borrow_in);
    state.af.bytes.lo |= s.FLAG_N;

    return res;
}

//INC r / INC (HL) / INC (IX+d): the carry flag is left untouched
pub fn inc_8bitReg(reg: *u8, state: *s.State) void{
    const old = reg.*;
    const result = old +% 1;

    setSignZeroFlags(state, result);
    //H: carry out of bit 3, which only happens when the low nibble was F
    setFlag(state, s.FLAG_H, (old & 0x0F) == 0x0F);
    //P/V: signed overflow, which only happens going from 7F (127) to 80 (-128)
    setFlag(state, s.FLAG_P, old == 0x7F);
    state.af.bytes.lo &= ~s.FLAG_N;
    reg.* = result;
}

//DEC r / DEC (HL) / DEC (IX+d): the carry flag is left untouched
pub fn dec_8bitReg(reg: *u8, state: *s.State) void{
    const old = reg.*;
    const result = old -% 1;

    setSignZeroFlags(state, result);
    //H: borrow from bit 4, which only happens when the low nibble was 0
    setFlag(state, s.FLAG_H, (old & 0x0F) == 0x00);
    //P/V: signed overflow, which only happens going from 80 (-128) to 7F (127)
    setFlag(state, s.FLAG_P, old == 0x80);
    state.af.bytes.lo |= s.FLAG_N;
    reg.* = result;
}

//sets S, Z, H and N from an 8-bit subtraction (a -% value producing result).
//does not touch the carry flag: some subtracting instructions (CPI/CPD/CPIR/CPDR)
//must leave carry untouched, so callers that need it (SUB/CP/SBC) set it themselves.
pub fn setSubtractionFlags(state: *s.State, a: u8, value: u8, result: u8) void {
    if(result == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }else{
        state.af.bytes.lo &= ~s.FLAG_Z;
    }

    if((result & 0x80) != 0){
        state.af.bytes.lo |= s.FLAG_S;
    }else{
        state.af.bytes.lo &= ~s.FLAG_S;
    }

    //H is set on a borrow out of bit 4
    if((a & 0xF) < (value & 0xF)){
        state.af.bytes.lo |= s.FLAG_H;
    }else{
        state.af.bytes.lo &= ~s.FLAG_H;
    }

    //N is always set for a subtraction
    state.af.bytes.lo |= s.FLAG_N;
}

//8-bit ALU helpers shared by the unprefixed and the DD/FD (IX/IY) instructions:
//each takes the operand value, sets the flags and returns the result for A

//A + value + carry_in, shared by ADD (carry_in = 0) and ADC (carry_in = carry flag)
fn add_a_with_carry(value: u8, carry_in: u8, state: *s.State) u8 {
    const a = state.af.bytes.hi;
    const sum: u16 = @as(u16, a) + value + carry_in;
    const res: u8 = @truncate(sum);

    setSignZeroFlags(state, res);
    //H is the carry out of bit 3
    setFlag(state, s.FLAG_H, (a & 0x0F) + (value & 0x0F) + carry_in > 0x0F);
    setFlag(state, s.FLAG_P, addOverflow(a, value, res));
    setFlag(state, s.FLAG_C, sum > 0xFF);
    state.af.bytes.lo &= ~s.FLAG_N;

    return res;
}

//A - value - borrow_in, shared by SUB/CP (borrow_in = 0) and SBC (borrow_in = carry flag)
fn sub_a_with_borrow(value: u8, borrow_in: u8, state: *s.State) u8 {
    const a = state.af.bytes.hi;
    const res: u8 = a -% value -% borrow_in;

    setSignZeroFlags(state, res);
    //H is set on a borrow from bit 4
    setFlag(state, s.FLAG_H, (a & 0x0F) < (value & 0x0F) + borrow_in);
    setFlag(state, s.FLAG_P, subOverflow(a, value, res));
    setFlag(state, s.FLAG_C, @as(u16, a) < @as(u16, value) + borrow_in);
    state.af.bytes.lo |= s.FLAG_N;

    return res;
}

pub fn add_a_value(value: u8, state: *s.State) u8{
    return add_a_with_carry(value, 0, state);
}

pub fn adc_a_value(value: u8, state: *s.State) u8{
    return add_a_with_carry(value, state.af.bytes.lo & s.FLAG_C, state);
}

pub fn sub_a_value(value: u8, state: *s.State) u8{
    return sub_a_with_borrow(value, 0, state);
}

pub fn sbc_a_value(value: u8, state: *s.State) u8{
    return sub_a_with_borrow(value, state.af.bytes.lo & s.FLAG_C, state);
}

//AND/XOR/OR: C and N are always reset, H is set only by AND, P/V holds the parity of the result
pub fn decode_binary_operation(value: u8, operation: op, state: *s.State) u8 {
    var res: u8 = state.af.bytes.hi;
    switch(operation){
        .And => res &= value,
        .Xor => res ^= value,
        .Or  => res |= value,
    }

    setSignZeroFlags(state, res);
    setFlag(state, s.FLAG_H, operation == .And);
    setFlag(state, s.FLAG_P, @popCount(res) % 2 == 0);
    state.af.bytes.lo &= ~(s.FLAG_N | s.FLAG_C);

    return res;
}

pub fn op_rlc(state: *s.State, reg: *u8) void {
    const bit7: u8 = (reg.* >> 7) & 1;

    //rotate and put bit7 in position 0
    reg.* = (reg.* << 1) | bit7;

    //reset flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    if(bit7 == 1) state.af.bytes.lo |= s.FLAG_C;
}

pub fn op_rrc(state: *s.State, reg: *u8) void {
    const bit0: u8 = reg.* & 1;

    //rotate
    reg.* = (reg.* >> 1) | (bit0 << 7);

    //set flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    if(bit0 == 1) state.af.bytes.lo |= s.FLAG_C;
}


pub fn op_rl(state: *s.State, reg: *u8) void {
    const bit7: u8 = (reg.* >> 7) & 1;

    const prevCarry: u8 = state.af.bytes.lo & s.FLAG_C;

    //rotate and set bit0 of reg to the prevCarry
    reg.* = (reg.* << 1) | prevCarry;

    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    if(bit7 == 1) state.af.bytes.lo |= s.FLAG_C;
}

pub fn op_rr(state: *s.State, reg: *u8) void {
    const bit0: u8 = reg.* & 1;
    const prevCarry: u8 = state.af.bytes.lo & s.FLAG_C;

    //rotate and insert into bit7 the previousCarry
    reg.* = (reg.* >> 1) | (prevCarry << 7);

    //reset flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    if(bit0 == 1) state.af.bytes.lo |= s.FLAG_C;
}

pub fn getRegister(r: Register, state: *s.State, base: IndexBase, d: i8) *u8{
    return switch(r){
        .B => &state.bc.bytes.hi,
        .C => &state.bc.bytes.lo,
        .D => &state.de.bytes.hi,
        .E => &state.de.bytes.lo,
        .H => &state.hl.bytes.hi,
        .L => &state.hl.bytes.lo,
        .A => &state.af.bytes.hi,
        //.HL=> &state.memory[state.hl.pair]
        .HL => state.bus.get_memory_ptr(indexedAddresses(state, base , d)),
    };
}

pub fn getRegisterValue(r: Register, state: *s.State, base: IndexBase, d: i8) u8{
    return switch(r){
        .B => state.bc.bytes.hi,
        .C => state.bc.bytes.lo,
        .D => state.de.bytes.hi,
        .E => state.de.bytes.lo,
        .H => state.hl.bytes.hi,
        .L => state.hl.bytes.lo,
        .A => state.af.bytes.hi,
        //.HL=> state.memory[state.hl.pair],
        .HL => state.bus.read_memory(indexedAddresses(state, base, d)),
    };
}

pub fn getRegisterPair(rp: RegisterPair, state: *s.State) *s.regPair {
    return switch(rp){
        .BC => &state.bc,
        .DE => &state.de,
        .HL => &state.hl,
        .AF => &state.af,
    };
}

pub fn get16BitRegister(r16: Reg16Bit, state: *s.State) *u16 {
    return switch(r16){
        .BC => &state.bc.pair,
        .DE => &state.de.pair,
        .HL => &state.hl.pair,
        .SP => &state.sp,
        .IX => &state.ix,
        .IY => &state.iy,
    };
}
pub fn setRegisterValue(r: Register, value: u8, state: *s.State, base:IndexBase, d: i8) void {
    switch(r){
        .B => state.bc.bytes.hi = value,
        .C => state.bc.bytes.lo = value,
        .D => state.de.bytes.hi = value,
        .E => state.de.bytes.lo = value,
        .H => state.hl.bytes.hi = value,
        .L => state.hl.bytes.lo = value,
        .A => state.af.bytes.hi = value,
        //.HL=> state.memory[state.hl.pair] = value,
        .HL => state.bus.write_memory(indexedAddresses(state, base, d), value),
    }
}

pub fn conditionMet(cond: Condition, state: *s.State) bool {
    return switch (cond) {
        .Z => (state.af.bytes.lo & s.FLAG_Z) != 0, 
        .NZ => (state.af.bytes.lo & s.FLAG_Z) == 0, 
        .C => (state.af.bytes.lo & s.FLAG_C) != 0,
        .NC => (state.af.bytes.lo & s.FLAG_C) == 0,
        .PE => (state.af.bytes.lo & s.FLAG_P) != 0,
        .PO => (state.af.bytes.lo & s.FLAG_P) == 0,
        .M => (state.af.bytes.lo & s.FLAG_S) != 0,
        .P => (state.af.bytes.lo & s.FLAG_S) == 0,
    };
}

pub fn push16BitValue(value: u16, state: *s.State) void {
    state.sp -%= 1;
    //state.memory[state.sp] = @intCast((value >> 8) & 0xFF); 
    state.bus.write_memory(state.sp, @intCast((value >> 8) & 0xFF));

    state.sp -%= 1;
    //state.memory[state.sp] = @intCast(value & 0xFF);
    state.bus.write_memory(state.sp, @intCast(value  & 0xFF));
}

pub fn pop16BitValue(state: *s.State) u16 {
    const lo = state.bus.read_memory(state.sp);
    state.sp +%= 1;

    const hi = state.bus.read_memory(state.sp);
    state.sp +%= 1;

    return @as(u16, hi) << 8 | lo;
}

//for the RST instructions: the target address is encoded in bits 3-5 (t*8)
pub fn getTargetAddress(value: u16) u8 {
    return @intCast(value & 0b00111000);
}
