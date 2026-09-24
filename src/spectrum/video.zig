const std = @import("std");

const hiResWidth: u8 = 256;
const hiResHeight: u8 = 192;

const loResWidth: u8 = 64;
const loResHeight: u8 = 32;

pub const PixelCoord = struct{
    x: u16,
    y: u16
};


pub const Video = struct {
    frame_buffer: [256][192]u32,
    flash_frames: u8,
    screen_coords: [6144]PixelCoord,

    pub fn init(self: *Video) void {

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

            self.screen_coords[offset].x = x_byte * 8;
            self.screen_coords[offset].y = (y_third * 64) + (y_line * 8) + y_row;
        }
    }

    pub fn resolve_address(self: *Video, x: u16, y: u16) u16 {
        var address: u16 = 0;

        //easy part
        const x_byte = x >> 3; 

        //64 is 2^6 
        const y_third = y >> 6;

        //1100 0000
        //0011 1111
        //
        const y_line = (y & 0x3F) >> 3;

        //0000 0111 
        const y_row = y & 0x07; 



        address |= (x_byte | y_row << 8 | y_line << 5 | y_third << 11);
        return address;
        
    }
    pub fn render(self: *Video, screen: *const [6192]u8) u8 {
        //screen[0..6144]    = pixel bitmap
        //screen[6144..6912] = attributes (32x24)
        _ = self;
        _ = screen;

        return 0;
    }


};


