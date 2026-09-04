const s = @import("../internals/state.zig");

//order matches the Z80's 3-bit register field encoding: (HL)=110, A=111
pub const Register = enum(u3){
    B, C, D, E, H, L, HL, A,
};

pub const RegisterPair = enum(u3){
    BC, DE, HL, AF
};

pub const Reg16Bit = enum(u3) {
    BC, DE, HL, SP
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

pub fn add_16bitRegs(reg1: u16, reg2: u16, state: *s.State) u16 {
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

pub fn inc_8bitReg(reg: *u8, state: *s.State) void{
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

pub fn inc_16bitReg(reg: *u16, state: *s.State) void{
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
pub fn dec_8bitReg(reg: *u8, state: *s.State) void{
    const res = @subWithOverflow(reg.*, 1);
    if(res[1] == 1){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;
    }

    if(res[0] == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }


    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);
    reg.* = res[0];
}

pub fn dec_16bitReg(reg: *u16, state: *s.State) void{
    const res = @subWithOverflow(reg.*, 1);
    if(res[1] == 1){
        //set the carry flag if an overflow happened
        state.af.bytes.lo |= s.FLAG_C;

    }

    if(res[0] == 0){
        //set the zero flag
        state.af.bytes.lo |= s.FLAG_Z;
    }


    //reset the N flag
    state.af.bytes.lo &= ~(s.FLAG_N);
    reg.* = res[0];
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

pub fn getRegister(r: Register, state: *s.State) *u8{
    return switch(r){
        .B => &state.bc.bytes.hi,
        .C => &state.bc.bytes.lo,
        .D => &state.de.bytes.hi,
        .E => &state.de.bytes.lo,
        .H => &state.hl.bytes.hi,
        .L => &state.hl.bytes.lo,
        .A => &state.af.bytes.hi,
        .HL=> &state.memory[state.hl.pair]
    };
}

pub fn getRegisterValue(r: Register, state: *s.State) u8{
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
    };
}
pub fn setRegisterValue(r: Register, value: u8, state: *s.State) void {
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
    state.memory[state.sp] = @intCast((value >> 8) & 0xFF); 

    state.sp -%= 1;
    state.memory[state.sp] = @intCast(value & 0xFF); 
}

//for the RST instructions: the target address is encoded in bits 3-5 (t*8)
pub fn getTargetAddress(value: u16) u8 {
    return @intCast(value & 0b00111000);
}
