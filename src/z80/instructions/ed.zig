const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

pub fn op_ldi(state: *s.State) u8 {
    //transfer contents from hl memory location to de memory location
    //const content: u8 = state.bus.read_memory(state.hl.pair); 
        
    state.bus.write_memory(state.de.pair, state.bus.read_memory(state.hl.pair));

    //increment both register pair and bc is decremented 
    state.hl.pair +%= 1;
    state.de.pair +%= 1;
    state.bc.pair -%= 1;

    //reset N and H flag
    state.af.bytes.lo &= ~(s.FLAG_N | s.FLAG_H);

    if(state.bc.pair != 0){
        //pv is set
        state.af.bytes.lo |= s.FLAG_P;
    }else {
        //reset
        state.af.bytes.lo &= ~(s.FLAG_P);
    }
    return 16;
}


pub fn op_cpi(state: *s.State) u8 {
    const a = state.af.bytes.hi;
    const value = state.bus.read_memory(state.hl.pair);
    const result: u8 = a -% value;

    //CPI computes S/Z/H/N like CP does, but must never touch the carry flag
    h.setSubtractionFlags(state, a, value, result);

    state.hl.pair +%= 1;
    state.bc.pair -%= 1;
    if(state.bc.pair != 0){
        //pv is set
        state.af.bytes.lo |= s.FLAG_P;
    }else{
        state.af.bytes.lo &= ~(s.FLAG_P);
    }

    return 16;
}

pub fn op_in(state: *s.State) u8 {
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    if(reg == h.Register.HL){
        //this case is unhandled or not documented
        return 0;
    }

    const value: u8 = state.bus.read_port(state.bc.pair);

    h.setRegisterValue(reg, value, state);

    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N | s.FLAG_Z | s.FLAG_S);

    if(value == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }

    if(value < 0){
        state.af.bytes.lo |= s.FLAG_S;
    }

    return 12;
}

pub fn op_out(state: *s.State) u8{
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));
    const reg = h.getRegister(src, state);

    if(reg == h.Register.HL){
        //this case is unhandled or not documented
        return 0;
    }
    const value:u8 = h.getRegisterValue(reg, state);

    state.bus.write_port(state.bc.pair, value);
    return 12;
}
