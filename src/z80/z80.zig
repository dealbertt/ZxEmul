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

    //one full cycle of z80, 70k per frame
    //there will need to be some sort of cycle counter that updates it in this function
    //but should that be part of the z80 state?
    pub fn cycle(self: *Z80) u16 {
        //retrieve the opcode
        self.state.opcode = e.fetch(&self.state);

        //decode, kind of?
        const handle = t.mainOpcodes[self.state.opcode];

        //execute, which i guess includes all of the write back, and operand read, etc
        const cycles = handle(&self.state);
        
        //execute
        //write back
        //whatever else is needed typeshee
        return cycles;
    }
};
