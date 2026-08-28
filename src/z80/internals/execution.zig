const std = @import("std");

const s = @import("state.zig");
const mem = @import("memory.zig");
const t = @import("../instructions/tables.zig");

pub fn fetch(state: *s.State) u8 {
    const opcode = mem.read8(state, &state.pc);

    state.pc +%= 1;
    std.debug.print("Current opcode {} \n", .{state.opcode});

    return opcode;
}

