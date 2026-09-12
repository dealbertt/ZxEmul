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

    key_matrix: [8]u8,

    pub fn read_memory(self: *Bus, address: u16) u8{
        return self.memory[address];
    }

    pub fn get_memory_ptr(self: *Bus, address: u16) *u8{
        return &self.memory[address];
    }
    pub fn write_memory(self: *Bus, address: u16, value:u8) void {
        if(address < 0x4000){
            //std.debug.print("ROM memory!\n", .{}); 
            return;
        }else{
            self.memory[address] = value;
        }
    }
    
    pub fn read_port(self: *Bus, port: u16) u8 {
        const base_port: u8 = port & 0x00FF; //gets the lower 8 bits

        //only reads if the bit0 of the port is 0
        //the ULA ignores if that bit is 1
        if((base_port & 0x01) == 0){
            const result: u8 = 0x1F;
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
        const base_port: u8 = port & 0x00FF;
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
