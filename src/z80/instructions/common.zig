const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");
//Functions that contain common logic across multiple instructions (main, bit, etc)
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
