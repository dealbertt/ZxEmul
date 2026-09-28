const std = @import("std");

const s = @import("../internals/state.zig");

const h = @import("helpers.zig");

const tables = @import("tables.zig");

const mem = @import("../internals/memory.zig");

const cb = @import("cb.zig");

//Opcode A0
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


//Opcode A8: LDD 
pub fn op_ldd(state: *s.State) u8 {
    //transfer contents from hl memory location to de memory location
    state.bus.write_memory(state.de.pair, state.bus.read_memory(state.hl.pair));

    //decrement both register pairs, and bc is decremented too
    state.hl.pair -%= 1;
    state.de.pair -%= 1;
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

//Opcode B0: LDIR 
pub fn op_ldir(state: *s.State) u8 {
    _ = op_ldi(state);

    if(state.bc.pair != 0){
        state.pc -%= 2;
        return 21;
    }
    return 16;
}

//Opcode B8: LDDR 
pub fn op_lddr(state: *s.State) u8 {
    _ = op_ldd(state);

    if(state.bc.pair != 0){
        state.pc -%= 2;
        return 21;
    }
    return 16;
}

//Opcode A1
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

//Opcode A9: CPD 
pub fn op_cpd(state: *s.State) u8 {
    const a = state.af.bytes.hi;
    const value = state.bus.read_memory(state.hl.pair);
    const result: u8 = a -% value;

    //CPD computes S/Z/H/N like CP does, but must never touch the carry flag
    h.setSubtractionFlags(state, a, value, result);

    state.hl.pair -%= 1;
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

    h.setRegisterValue(src, value, state, .HL, 0);

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
    const value:u8 = h.getRegisterValue(src, state, .HL, 0);

    state.bus.write_port(state.bc.pair, value);
    return 12;
}

//Opcodes 43/53/63/73: LD (nn),rr 
pub fn decode_ld_nn_addr_rr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    mem.write8(state, nn, @intCast(reg.* & 0xFF));
    mem.write8(state, nn +% 1, @intCast((reg.* >> 8) & 0xFF));

    return 20;
}

//Opcodes 4B/5B/6B/7B: LD rr,(nn) 
pub fn decode_ld_rr_nn_addr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    const lo = state.bus.read_memory(nn);
    const hi = state.bus.read_memory(nn +% 1);
    reg.* = @as(u16, hi) << 8 | lo;

    return 20;
}

//Opcodes 4A/5A/6A/7A: ADC HL,rr 
pub fn decode_adc_hl_rr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    //read into a local first, so ADC HL,HL uses HL's value from before the write
    const value = h.get16BitRegister(src, state).*;

    state.hl.pair = h.adc_16bit(state.hl.pair, value, state);
    return 15;
}

//Opcodes 42/52/62/72: SBC HL,rr - HL = HL - rr - carry, every flag affected
pub fn decode_sbc_hl_rr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    //read into a local first, so SBC HL,HL uses HL's value from before the write
    const value = h.get16BitRegister(src, state).*;

    state.hl.pair = h.sbc_16bit(state.hl.pair, value, state);
    return 15;
}

//Opcode 47: LD I,A - no flags affected
pub fn op_ld_i_a(state: *s.State) u8 {
    state.i = state.af.bytes.hi;
    return 9;
}

//Opcode 4F: LD R,A - no flags affected
pub fn op_ld_r_a(state: *s.State) u8 {
    state.r = state.af.bytes.hi;
    return 9;
}

//Opcode 57: LD A,I
pub fn op_ld_a_i(state: *s.State) u8 {
    state.af.bytes.hi = state.i;

    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N | s.FLAG_Z | s.FLAG_S | s.FLAG_P);

    if(state.i == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //80 is 1000 0000, we only want to test bit7
    if((state.i & 0x80) != 0){
        state.af.bytes.lo |= s.FLAG_S;
    }

    //this is the only place software can observe IFF2
    if(state.iff2 == true){
        state.af.bytes.lo |= s.FLAG_P;
    }
    return 9;
}

//Opcode 5F: LD A,R
pub fn op_ld_a_r(state: *s.State) u8 {
    state.af.bytes.hi = state.r;

    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N | s.FLAG_Z | s.FLAG_S | s.FLAG_P);

    if(state.r == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }

    //80 is 1000 0000, we only want to test bit7
    if((state.r & 0x80) != 0){
        state.af.bytes.lo |= s.FLAG_S;
    }

    //this is the only place software can observe IFF2
    if(state.iff2 == true){
        state.af.bytes.lo |= s.FLAG_P;
    }
    return 9;
}

//Opcode 45: RETN 
pub fn op_retn(state: *s.State) u8 {
    state.pc = h.pop16BitValue(state);
    state.iff1 = state.iff2;
    return 14;
}

//Opcode 4D: RETI 
pub fn op_reti(state: *s.State) u8 {
    state.pc = h.pop16BitValue(state);
    state.iff1 = state.iff2;
    return 14;
}

//Opcode 46: IM 0 
pub fn op_im_0(state: *s.State) u8 {
    state.im = s.InterruptMode.IM0;
    return 8;
}

//Opcode 56: IM 1 
pub fn op_im_1(state: *s.State) u8 {
    state.im = s.InterruptMode.IM1;
    return 8;
}

//Opcode 5E: IM 2 
pub fn op_im_2(state: *s.State) u8 {
    state.im = s.InterruptMode.IM2;
    return 8;
}

//every ED opcode with no instruction assigned (00-3F, 80-9F, C0-FF and the gaps between the
pub fn op_nop_invalid(state: *s.State) u8 {
    _ = state;
    return 8;
}

//Opcode 44: NEG 
pub fn op_neg(state: *s.State) u8 {
    const original = state.af.bytes.hi;
    state.af.bytes.hi = 0;

    state.af.bytes.hi = h.sub_a_value(original, state);
    return 8;
}

//Opcode 67: RRD 
pub fn op_rrd(state: *s.State) u8{
    const value = state.bus.read_memory(state.hl.pair);

    //nibble extraction
    const a_low = state.af.bytes.hi & 0x0F;
    const m_low = value & 0x0F;
    const m_high = value >> 4;

    state.af.bytes.hi = (state.af.bytes.hi & 0xF0) | m_low;
    const new_value = (a_low << 4) | m_high;

    state.bus.write_memory(state.hl.pair, new_value);

    //S, Z and P/V (parity) come from the new A, H and N are reset, C is left untouched
    cb.setZSPFlag(state, state.af.bytes.hi);
    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N);

    return 18;
}

//Opcode 6F: RLD 
pub fn op_rld(state: *s.State) u8{
    const value = state.bus.read_memory(state.hl.pair);

    //nibble extraction
    const a_low = state.af.bytes.hi & 0x0F;
    const m_low = value & 0x0F;
    const m_high = value >> 4;

    state.af.bytes.hi = (state.af.bytes.hi & 0xF0) | m_high;
    const new_value = (m_low << 4) | a_low;

    state.bus.write_memory(state.hl.pair, new_value);

    //S, Z and P/V (parity) come from the new A, H and N are reset, C is left untouched
    cb.setZSPFlag(state, state.af.bytes.hi);
    state.af.bytes.lo &= ~(s.FLAG_H | s.FLAG_N);

    return 18;
}


//Opcode A2: INI 
pub fn op_ini(state: *s.State) u8 {
    const byte: u8 = state.bus.read_port(state.bc.pair); 
    state.bus.write_memory(state.hl.pair, byte);


    state.hl.pair +%= 1;
    state.bc.bytes.hi -%= 1;

    h.setFlag(state, s.FLAG_Z, state.bc.bytes.hi == 0);
    state.af.bytes.lo |= s.FLAG_N;
    
    return 16;
}

//Opcode B2: INIR
pub fn op_inir(state: *s.State) u8 {
    _ = op_ini(state);
    
    if(state.bc.bytes.hi != 0){
        state.pc -%= 2;
        return 21;
    }
    return 16;
}
