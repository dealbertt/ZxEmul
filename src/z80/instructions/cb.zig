const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const c = @import("common.zig");
const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

//types of instructions here
//rlc 
//
//sla

fn regOrHLCycles(reg: h.Register) u8 {
    return if (reg == .HL) 15 else 8;
}

fn setZSPFlag(state: *s.State, result: u8) void {
    //flag z
    if(result == 0) state.af.bytes.lo |= s.FLAG_Z;
    //flag s
    if((result & 0x80) != 0) state.af.bytes.lo |= s.FLAG_S; 
    //flag p
    if((@popCount(result) % 2) == 0) state.af.bytes.lo |= s.FLAG_P;
        
}

pub fn decode_rlc(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rlc(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}


pub fn decode_rrc(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rrc(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_rl(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rl(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_rr(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rr(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_sla(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sla(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

fn op_sla(state: *s.State, reg: *u8) void {
    const bit7: u8 = reg.* & 0x80;

    //shifted, automatically puts a 0 on bit0
    reg.* = (reg.* << 1);
    //reset flags
    //
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    if(bit7 == 1) state.af.bytes.lo |= s.FLAG_C;
}

pub fn decode_sra(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sra(state, &reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
} 

fn op_sra(state: *s.State, reg: *u8) void {
    const bit0: u8 = reg.* & 1;
    const bit7: u8 = reg.* & 0x80;

    //shifted, and contents of bit7 remain unchanged
    reg.* = (reg.* >> 1) | bit7;

    //reset flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    //contents of bit0 copied to carry flag
    if(bit0 == 1) state.af.bytes.lo |= s.FLAG_C;

}
