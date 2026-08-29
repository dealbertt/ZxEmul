const s = @import("internals/state.zig");
const t = @import("instructions/tables.zig");
const e = @import("internals/execution.zig");

pub const Z80 = struct {
    state: s.State,

    pub fn init(memory: []u8) Z80 {
        t.initTables();
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

                .opcode = 0,
            }
        };
    } 

    pub fn step(self: *Z80, state: *s.State) void {
        self.state.opcode = e.fetch(state);

        const handle = t.mainOpcodes[self.state.opcode];

        handle(state);

        //decode
        //execute
        //write back
        //whatever else is needed typeshee
    }
};
