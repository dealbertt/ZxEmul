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
    if(src == h.Register.HL){
        //this case is unhandled or not documented
        return 0;
    }

    const value: u8 = state.bus.read_port(state.bc.pair);

    h.setRegisterValue(src, value, state);

    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N | s.FLAG_Z | s.FLAG_S | s.FLAG_P);

    if(value == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //80 is 1000 0000, we only want to test bit7
    if((value & 0x80) != 0){
        state.af.bytes.lo |= s.FLAG_S;
    }
    if((@popCount(value) % 2) == 0) state.af.bytes.lo |= s.FLAG_P;

    return 12;
}

pub fn op_out(state: *s.State) u8{
    const src: h.Register = @enumFromInt(@as(u8, @intCast((state.opcode >> 3) & 0b111)));

    if(src == h.Register.HL){
        //this case is unhandled or not documented
        return 0;
    }
    const value:u8 = h.getRegisterValue(src, state);

    state.bus.write_port(state.bc.pair, value);
    return 12;
}

//Opcodes 43/53/63/73: LD (nn),rr - stores a 16-bit register pair to memory
pub fn decode_ld_nn_addr_rr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    mem.write8(state, nn, @intCast(reg.* & 0xFF));
    mem.write8(state, nn + 1, @intCast((reg.* >> 8) & 0xFF));

    return 20;
}

//Opcodes 4B/5B/6B/7B: LD rr,(nn) - loads a 16-bit register pair from memory
pub fn decode_ld_rr_nn_addr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    const lo = state.bus.read_memory(nn);
    const hi = state.bus.read_memory(nn + 1);
    reg.* = @as(u16, hi) << 8 | lo;

    return 20;
}
