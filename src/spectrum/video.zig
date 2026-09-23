const std = @import("std");

const hiResWidth: u8 = 256;
const hiResHeight: u8 = 192;

const loResWidth: u8 = 64;
const loResHeight: u8 = 32;


pub const PixelCoord = struct{
    x: u16,
    y: u16
};

var screenCords:[6144]PixelCoord = undefined; 

pub fn initDisplay() void {
    //address of 16 bits
    //0000 0000 0000 0000
    for(0..6144) |offset| {
        const off: u16 = @intCast(offset);
       
        //bits 0 to 4
        const x_byte = (off & 0x001F);

        //bits 8 to 10
        const y_row = (off & 0x0700) >> 8; 

        //bits 5 to 7
        const y_line = (off & 0x00E0) >> 5; 

        //bits 11 to 12
        const y_third = (off & 0x1800) >> 11;


        screenCords[offset].x = x_byte * 8;
        screenCords[offset].y = (y_third * 64) + (y_line * 8) + y_row;
    }
}

pub fn refresh_screen() u8 {
    //screen-attached memory is from 0x4000 - 0x57FF          
    return 0;
}
