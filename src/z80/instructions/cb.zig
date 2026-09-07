const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

//types of instructions here
//rlc 
//
//sla

fn regOrHLCycles(reg: h.Register) u8 {
    return if (reg == .HL) 15 else 8;
}

fn regOrHLCyclesBit(reg: h.Register) u8 {
    return if (reg == .HL) 12 else 8;
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
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);

    h.op_rlc(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}


pub fn decode_rrc(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);

    h.op_rrc(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_rl(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);

    h.op_rl(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_rr(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);

    h.op_rr(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

pub fn decode_sla(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sla(state, reg);

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

    if(bit7 != 0) state.af.bytes.lo |= s.FLAG_C;
}

pub fn decode_sra(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sra(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
} 

fn op_sra(state: *s.State, reg: *u8) void {
    const bit0: u8 = reg.* & 1;
    const bit7: u8 = (reg.* >> 7) & 1;

    //shifted, and contents of bit7 remain unchanged
    reg.* = (reg.* >> 1) | bit7;

    //reset flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    //contents of bit0 copied to carry flag
    if(bit0 == 1) state.af.bytes.lo |= s.FLAG_C;
}

pub fn decode_sll(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);
    op_sll(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

fn op_sll(state: *s.State, reg: *u8) void {
    const bit7: u8 = (reg.* >> 7) & 1;

    //shifted, and a 1 is inserted on bit0 (this is what makes SLL distinct from SLA)
    reg.* = (reg.* << 1) | 1;
    //reset flags
    //
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    if(bit7 == 1) state.af.bytes.lo |= s.FLAG_C;

}


pub fn decode_srl(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);
    op_srl(state, reg);

    setZSPFlag(state, reg.*);
    return regOrHLCycles(src);
}

fn op_srl(state: *s.State, reg: *u8) void {
    const bit0: u8 = reg.* & 1;

    //shifted, and bit7 gets put to 0 
    reg.* = (reg.* >> 1);

    //reset flags
    state.af.bytes.lo &= ~(s.FLAG_C | s.FLAG_N | s.FLAG_H);

    //contents of bit0 copied to carry flag
    if(bit0 == 1) state.af.bytes.lo |= s.FLAG_C;
}

//for bit0
//40
//0100 0000
//41
//0100 0001
//
//for bit1
//48
//0100 1000
//49
//0100 1001
//the first byte is for the CB prefix
//the second byte:
//01 - bbb - rrr
//01 -> 64
//01-xxx-yyy
//01-xxx-111
//
pub fn decode_bit(state: *s.State) u8 {
    const bit: u3 = @intCast((state.opcode >> 3) & 0b111);

    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode) & 0b111)));
    const reg = h.getRegister(src, state);
    
    op_bit(state, reg, bit);
    return regOrHLCyclesBit(src);
}

fn op_bit(state: *s.State, reg: *u8, bit: u3) void {
    const testBit = (reg.* >> bit) & 1;  

    if(testBit == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }else{
        state.af.bytes.lo &= ~s.FLAG_Z;
    }

    //set H
    state.af.bytes.lo |= s.FLAG_H;
    //reset N
    state.af.bytes.lo &= ~s.FLAG_N;
}
