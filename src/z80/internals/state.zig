const std = @import("std");

pub const InterruptMode = enum(u3) {
    IM0, IM1, IM2
};

pub const regPair = extern union { pair: u16, bytes: extern struct {
    lo: u8,
    hi: u8,
    }
};

pub const State = struct{
    af: regPair,
    bc: regPair,
    de: regPair,
    hl: regPair,

    //shadow set (AF', BC', DE', HL'): only reachable by swapping with EX AF,AF' and EXX
    af_shadow: regPair,
    bc_shadow: regPair,
    de_shadow: regPair,
    hl_shadow: regPair,

    ix: u16,
    iy: u16,
    sp: u16,
    pc: u16,

    im: InterruptMode,

    //special registers
    i: u8,
    r: u8,

    //internal cpu bookkeeping, interrupt
    iff1: bool,
    iff2: bool,
    halted: bool,
    ei_defer: bool,

    bus: Bus,
    opcode: u8,

    //prints every cpu register and internal flag for debugging. the 64K of memory is left out
    pub fn report(self: *const State) void {
        std.debug.print("AF={X:0>4}  BC={X:0>4}  DE={X:0>4}  HL={X:0>4}\n", .{ self.af.pair, self.bc.pair, self.de.pair, self.hl.pair });
        std.debug.print("AF'={X:0>4} BC'={X:0>4} DE'={X:0>4} HL'={X:0>4}\n", .{ self.af_shadow.pair, self.bc_shadow.pair, self.de_shadow.pair, self.hl_shadow.pair });
        std.debug.print("IX={X:0>4}  IY={X:0>4}  SP={X:0>4}  PC={X:0>4}\n", .{ self.ix, self.iy, self.sp, self.pc });
        std.debug.print("I={X:0>2}  R={X:0>2}  IM={s}  IFF1={}  IFF2={}\n", .{ self.i, self.r, @tagName(self.im), self.iff1, self.iff2 });
        std.debug.print("halted={}  ei_defer={}  opcode={X:0>2}\n", .{ self.halted, self.ei_defer, self.opcode });
        self.reportFlags();
        self.reportBus();
    }

    fn reportFlags(self: *const State) void {
        const f = self.af.bytes.lo;
        std.debug.print("flags: S={} Z={} H={} P/V={} N={} C={}\n", .{
            @intFromBool((f & FLAG_S) != 0),
            @intFromBool((f & FLAG_Z) != 0),
            @intFromBool((f & FLAG_H) != 0),
            @intFromBool((f & FLAG_P) != 0),
            @intFromBool((f & FLAG_N) != 0),
            @intFromBool((f & FLAG_C) != 0),
        });
    }

    fn reportBus(self: *const State) void {
        std.debug.print("bus: border={}  int_req={}  rom_protected={}\n", .{ self.bus.border_color, self.bus.int_req, self.bus.rom_protected });
        std.debug.print("key matrix:", .{});
        for(self.bus.key_matrix) |row| std.debug.print(" {X:0>2}", .{row});
        std.debug.print("\n", .{});
    }
};

pub const Bus = struct{
    //3 memory arrays
    //rom
    //lower ram
    memory: [65536]u8,

    border_color: u8,

    key_matrix: [8]u8,

    int_req: bool,

    rom_protected: bool,

    pub fn read_memory(self: *Bus, address: u16) u8{
        return self.memory[address];
    }

    pub fn get_memory_ptr(self: *Bus, address: u16) *u8{
        return &self.memory[address];
    }
    pub fn write_memory(self: *Bus, address: u16, value:u8) void {
        if(address < 0x4000 and self.rom_protected){
            //std.debug.print("ROM memory!\n", .{}); 
            return;
        }else{
            self.memory[address] = value;
        }
    }
    
    pub fn read_port(self: *Bus, port: u16) u8 {
        const base_port: u8 = @truncate(port);

        //only reads if the bit0 of the port is 0
        //the ULA ignores if that bit is 1
        if((base_port & 0x01) == 0){
            var result: u8 = 0x1F;
            const high_byte:u8 = @intCast(port >> 8); 

            //to read a row, the corresponding bit is set to 0
            inline for(0..8) |row| {
                if((high_byte & (@as(u8, 1) << row)) == 0){
                    result &= self.key_matrix[row]; //then you can check if the key (or bit) is set to 0
                }
            }
            return result;
        }
        return 0xFF;
    }

    pub fn write_port(self: *Bus, port: u16, value: u8) void {
        const base_port: u8 = @truncate(port);
        if((base_port & 0x01) == 0){
            self.border_color = value & 0x07;            
            //things for other bits like MIC TAPE
            //mic_level for bit 3
            //speaker beeper for bit4
            //the rest unused
        }
    }
    pub fn get_border_color(self: *Bus) u8{
        return self.border_color;
    }
};

pub const FLAG_C: u8 = 0b0000_0001;
pub const FLAG_N: u8 = 0b0000_0010;
pub const FLAG_P: u8 = 0b0000_0100;
pub const FLAG_H: u8 = 0b0001_0000;
pub const FLAG_Z: u8 = 0b0100_0000;
pub const FLAG_S: u8 = 0b1000_0000;
