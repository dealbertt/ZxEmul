const s = @import("internals/state.zig");
const t = @import("instructions/tables.zig");
const e = @import("internals/execution.zig");

const std = @import("std");
pub const Z80 = struct {
    state: s.State,

    pub fn init() Z80 {
        t.initTables();
        return Z80 {
            .state =  s.State{
                .pc = 0x0000,
                .sp = 0xFFFF,
                .af = .{ .pair = 0 },
                .bc = .{ .pair = 0 },
                .de = .{ .pair = 0 },
                .hl = .{ .pair = 0 },
                .ix = 0,
                .iy = 0,

                .bus = s.Bus {
                    .border_color = 7,
                    .memory = [_]u8{0} ** 65536,
                    .key_matrix = [_]u8 {0x1F} ** 8, 
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
        const prefix = e.fetch_byte(&self.state);

        const handle = switch (prefix) {
            0xCB => cb: { 
                self.state.opcode = e.fetch_byte(&self.state); 
                break: cb t.cbOpcodes[self.state.opcode];
            }, //the code block itself returns the cbOpcodes.table
            //0xDD => //
                    //,
            //0xFD => //,
            //0xED => //,
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
        const cycles = handle(&self.state);
        
        //execute
        //write back
        //whatever else is needed typeshee
        return cycles;
    }
};
