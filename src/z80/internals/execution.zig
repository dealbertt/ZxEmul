const std = @import("std");

const s = @import("state.zig");
const mem = @import("memory.zig");
const t = @import("../instructions/tables.zig");
const h = @import("../instructions/helpers.zig");

pub fn fetch_byte(state: *s.State) u8 {
    const byte = mem.read8(state, &state.pc);
    //std.debug.print("Current opcode {} \n", .{state.opcode});

    return byte;
}

pub fn handle_interrupts(state: *s.State) u8{
    if(state.ei_defer == true){
        state.ei_defer = false;
        return 0;
    }

    if(state.bus.int_req == false) return 0;

    //assumes that state.bus.int_req is true from this point
    if(state.iff1 == true){
        //interrup happens
        //clear both, not just iff1, and also int_req
        state.iff1 = false;
        state.iff2 = false;
        state.bus.int_req = false;
        state.halted = false;

        //every mode pushes the return address, only the destination and the cost change
        h.push16BitValue(state.pc, state);

        switch(state.im){
            //nothing drives the data bus on the spectrum, so it floats to FF, which is
            //RST 38h - the same destination IM 1 always uses
            .IM0, .IM1 => {
                state.pc = 0x0038;
                return 13;
            },
            //the handler address is read from a table indexed by (I << 8) | the bus byte (FF here)
            .IM2 => {
                const vector: u16 = (@as(u16, state.i) << 8) | 0xFF;
                const lo = state.bus.read_memory(vector);
                const hi = state.bus.read_memory(vector +% 1);

                state.pc = @as(u16, hi) << 8 | lo;
                return 19;
            },
        }
    }

    return 0;
}

