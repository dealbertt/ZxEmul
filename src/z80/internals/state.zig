pub const memorySize: u32 = 65536;

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

    
    memory: []u8,
};

pub const FLAG_C: u8 = 0b0000_0001;
pub const FLAG_N: u8 = 0b0000_0010;
pub const FLAG_P: u8 = 0b0000_0100;
pub const FLAG_H: u8 = 0b0001_0000;
pub const FLAG_Z: u8 = 0b0100_0000;
pub const FLAG_S: u8 = 0b1000_0000;
