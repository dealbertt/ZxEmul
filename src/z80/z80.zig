const s = @import("internals/state.zig");

pub const Z80 = struct {
    state: s.State,

    pub fn init(memory: []u8) Z80 {
        return Z80 {
            .state =  s.State{
                .memory = memory, 
                .pc = 0x0000,
                .sp = 0xFFFF,
                .af = .{ .pair = 0 },
                .bc = .{ .pair = 0 },
                .de = .{ .pair = 0 },
                .hl = .{ .pair = 0 },
                .ix = 0,
                .iy = 0,
            }
        };
    } 
};
