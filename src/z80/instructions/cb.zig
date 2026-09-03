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

pub fn decode_rlc(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rlc(state, &reg);

    return regOrHLCycles(src);
}


pub fn decode_rrc(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rrc(state, &reg);

    return regOrHLCycles(src);
}

pub fn decode_rl(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rl(state, &reg);

    return regOrHLCycles(src);
}

pub fn decode_rr(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    c.op_rr(state, &reg);

    return regOrHLCycles(src);
}

pub fn decode_sla(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sla(state, &reg);

    return regOrHLCycles(src);
}

fn op_sla(state: *s.State, reg: u8) void {
    const bit7: u8 = (reg >> 7) & 1;

    //shifted
    reg = (reg << 1);
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);
    state.af.bytes.lo |= bit7;
}
