const s = @import("state.zig");

pub fn read8(state: *s.State, pc: *u16) u8 {
    const value = state.memory[pc.*];
    pc.* += 1;
    return value; 
}

pub fn write8(state: *s.State, addr: u16, value: u8) void {
    state.memory[addr] = value; 
}

pub fn read16(state: *s.State, pc: *u16) u16 {
    const lo = state.memory[pc.*];
    pc.* += 1;

    const hi = state.memory[pc.*];
    pc.* += 1;

    return @as(u16, hi) << 8 | lo;
}


