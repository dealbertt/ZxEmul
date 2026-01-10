const std = @import("std");

const s = @import("state.zig");
const mem = @import("memory.zig");
const t = @import("../instructions/tables.zig");

pub fn fetch(state: *s.State) u8 {
    const opcode = mem.read8(state.pc);
    state.pc +%= 1;
    std.debug.print("Current opcode {} \n", .{state.opcode});
    return opcode;
}

pub fn step(state: *s.State) void {
    const opcode = fetch(state);
    const handle = t.mainOpcodes[opcode]; 
    handle(state);
    //decode
    //execute
    //write back
    //whatever else is needed typeshee
}
