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

//Opcodes 43/53/63/73: LD (nn),rr - stores a 16-bit register pair to memory
pub fn decode_ld_nn_addr_rr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    mem.write8(state, nn, @intCast(reg.* & 0xFF));
    mem.write8(state, nn +% 1, @intCast((reg.* >> 8) & 0xFF));

    return 20;
}

//Opcodes 4B/5B/6B/7B: LD rr,(nn) - loads a 16-bit register pair from memory
pub fn decode_ld_rr_nn_addr(state: *s.State) u8 {
    const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
    const reg = h.get16BitRegister(src, state);

    const nn = mem.read16(state, &state.pc);
    const lo = state.bus.read_memory(nn);
    const hi = state.bus.read_memory(nn +% 1);
    reg.* = @as(u16, hi) << 8 | lo;

    return 20;
}

//Opcodes 4A/5A/6A/7A: ADC HL,rr - HL = HL + rr + carry, every flag affected
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

//Opcode 45: RETN - returns from an NMI, restoring the interrupt enable that accepting it cleared
pub fn op_retn(state: *s.State) u8 {
    state.pc = h.pop16BitValue(state);
    state.iff1 = state.iff2;
    return 14;
}

//Opcode 4D: RETI - returns from a maskable interrupt. on real silicon it shares RETN's path
//and restores IFF1 the same way, even though zilog's docs only describe the pc pop.
//the difference on real hardware is the bus pattern it emits for daisy-chained peripherals
pub fn op_reti(state: *s.State) u8 {
    state.pc = h.pop16BitValue(state);
    state.iff1 = state.iff2;
    return 14;
}

//Opcode 46: IM 0 - the interrupting device puts an instruction on the bus for the cpu to run
pub fn op_im_0(state: *s.State) u8 {
    state.im = s.InterruptMode.IM0;
    return 8;
}

//Opcode 56: IM 1 - always restarts at 0x0038. this is what the spectrum rom selects
pub fn op_im_1(state: *s.State) u8 {
    state.im = s.InterruptMode.IM1;
    return 8;
}

//Opcode 5E: IM 2 - vectored: the handler address is read from a table indexed by I
pub fn op_im_2(state: *s.State) u8 {
    state.im = s.InterruptMode.IM2;
    return 8;
}

//every ED opcode with no instruction assigned (00-3F, 80-9F, C0-FF and the gaps between the
//block instructions): the Z80 does nothing and just spends the 8 T-states of fetching both bytes
pub fn op_nop_invalid(state: *s.State) u8 {
    _ = state;
    return 8;
}
