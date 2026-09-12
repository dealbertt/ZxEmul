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
    state.hl.pair += 1;
    state.de.pair += 1;
    state.bc.pair -= 1;

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
    const result: i16 = @as(i16, state.bus.read_memory(state.hl.pair)) - @as(i16, state.af.bytes.hi);

    if(result == 0){
        state.af.bytes.lo |= s.FLAG_Z;
    }else if(result < 0){
        state.af.bytes.lo |= s.FLAG_S;
    }else{
        state.af.bytes.lo &= ~(s.FLAG_Z | s.FLAG_S);
    }


    //N is set no matter what
    state.af.bytes.lo |= s.FLAG_N;

    state.hl.pair += 1;
    state.bc.pair -= 1;
    if(state.bc.pair != 0){
        //pv is set
        state.af.bytes.lo |= s.FLAG_P;
    }else{
        state.af.bytes.lo &= ~(s.FLAG_P);
    }

    return 16;
}
