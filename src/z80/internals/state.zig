const std = @import("std");

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

    ix: u16,
    iy: u16,
    sp: u16,
    pc: u16,

    bus: Bus,
    opcode: u8,
};

pub const Bus = struct{
    //3 memory arrays
    //rom
    //lower ram
    memory: [65536]u8,

    border_color: u8,

    key_matrix: []u8,

    pub fn read_memory(self: *Bus, address: u16) u8{
        return self.memory[address];
    }

    pub fn write_memory(self: *Bus, address: u16, value:u8) void {
        if(address < 0x4000){
            std.debug.print("ROM memory!\n", .{}); 
        }else{
            self.memory[address] = value;
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
