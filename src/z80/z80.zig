const s = @import("internals/state.zig");
const t = @import("instructions/tables.zig");

const e = @import("internals/execution.zig");

const std = @import("std");
pub const Z80 = struct {
    state: s.State,

    pub fn init(self: *Z80) void {
        t.initTables();
        self.*  = Z80 {
            .state =  s.State{
                .pc = 0x0000,
                .sp = 0xFFFF,
                .af = .{ .pair = 0 },
                .bc = .{ .pair = 0 },
                .de = .{ .pair = 0 },
                .hl = .{ .pair = 0 },

                .af_shadow = .{ .pair = 0 },
                .bc_shadow = .{ .pair = 0 },
                .de_shadow = .{ .pair = 0 },
                .hl_shadow = .{ .pair = 0 },
                .ix = 0,
                .iy = 0,

                .i = 0,
                .r = 0,

                .im = s.InterruptMode.IM0,
                .iff1 = false,
                .iff2 = false,
                .halted = false,
                .ei_defer = false,

                .bus = s.Bus {
                    .border_color = 7,
                    .memory = [_]u8{0} ** 65536,
                    .key_matrix = [_]u8 {0x1F} ** 8, 
                    .int_req = false,
                },
                .opcode = 0,
            }
        };
    } 

    //one full cycle of z80, 70k per frame
    //there will need to be some sort of cycle counter that updates it in this function
    //but should that be part of the z80 state?
    pub fn cycle(self: *Z80) u16 {
        //retrieve the opcode
        //const prefix: u8 = e.fetch_byte(&self.state);
        const int_cycles = e.handle_interrupts(&self.state);

        //an accepted interrupt takes the place of this step's fetch, so nothing else runs
        if(int_cycles > 0) return int_cycles;

        if(self.state.halted == true) return 4;

        const prefix = e.fetch_byte(&self.state);

        const handle = switch (prefix) {
            0xCB => cb: {
                self.state.opcode = e.fetch_byte(&self.state);
                break: cb t.cbOpcodes[self.state.opcode];
            }, //the code block itself returns the cbOpcodes.table
            0xED => ed: {
                self.state.opcode = e.fetch_byte(&self.state);
                break: ed t.edOpcodes[self.state.opcode];
            },
            0xDD => dd: {
                self.state.opcode = e.fetch_byte(&self.state);
                break: dd t.ddOpcodes[self.state.opcode];
            },

            0xFD => fd: {
                self.state.opcode = e.fetch_byte(&self.state);
                break: fd t.fdOpcodes[self.state.opcode];
            },
            else => mn: {
                self.state.opcode = prefix;
                break: mn t.mainOpcodes[self.state.opcode];
            }
        };

        //shit i might need a decode part, to decode the bytes depending on the type of instructions
        //once i have fetched the opcode, i have to decode depending on the prefix
        //std.debug.print("Opcode: {}", .{self.state.opcode});
        //decode, kind of?

        //execute, which i guess includes all of the write back, and operand read, etc
        return handle(&self.state);
    }
};
