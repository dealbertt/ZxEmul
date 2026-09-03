const std = @import("std");

const s = @import("state.zig");
const mem = @import("memory.zig");
const t = @import("../instructions/tables.zig");

pub fn fetch_byte(state: *s.State) u8 {
    const byte = mem.read8(state, &state.pc);

    //increase pc, avoiding overflow with %
    state.pc +%= 1;

    //std.debug.print("Current opcode {} \n", .{state.opcode});

    return byte;
}

