const std = @import("std");

const rl_texture = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

//intensity of a colour channel that is on: normal and BRIGHT (values vary between emulators)
const NORMAL = 0xD7;
const BRIGHT = 0xFF;

//the 16 spectrum colours, indexed by bright * 8 + colour.
//the 3-bit colour number is laid out as G R B (bit 2 green, bit 1 red, bit 0 blue),
//and black stays black with BRIGHT set
pub const palette = [16]rl_texture{
    //normal
    .{ .r = 0,      .g = 0,      .b = 0,      .a = 0xFF }, //0 black
    .{ .r = 0,      .g = 0,      .b = NORMAL, .a = 0xFF }, //1 blue
    .{ .r = NORMAL, .g = 0,      .b = 0,      .a = 0xFF }, //2 red
    .{ .r = NORMAL, .g = 0,      .b = NORMAL, .a = 0xFF }, //3 magenta
    .{ .r = 0,      .g = NORMAL, .b = 0,      .a = 0xFF }, //4 green
    .{ .r = 0,      .g = NORMAL, .b = NORMAL, .a = 0xFF }, //5 cyan
    .{ .r = NORMAL, .g = NORMAL, .b = 0,      .a = 0xFF }, //6 yellow
    .{ .r = NORMAL, .g = NORMAL, .b = NORMAL, .a = 0xFF }, //7 white

    //bright
    .{ .r = 0,      .g = 0,      .b = 0,      .a = 0xFF }, //8  black
    .{ .r = 0,      .g = 0,      .b = BRIGHT, .a = 0xFF }, //9  blue
    .{ .r = BRIGHT, .g = 0,      .b = 0,      .a = 0xFF }, //10 red
    .{ .r = BRIGHT, .g = 0,      .b = BRIGHT, .a = 0xFF }, //11 magenta
    .{ .r = 0,      .g = BRIGHT, .b = 0,      .a = 0xFF }, //12 green
    .{ .r = 0,      .g = BRIGHT, .b = BRIGHT, .a = 0xFF }, //13 cyan
    .{ .r = BRIGHT, .g = BRIGHT, .b = 0,      .a = 0xFF }, //14 yellow
    .{ .r = BRIGHT, .g = BRIGHT, .b = BRIGHT, .a = 0xFF }, //15 white
};


pub const Video = struct {
    frame_buffer: [192][256]rl_texture,
    flash_frames: u8,

    pub fn init(self: *Video) void {
        for(0..192) |y|{
            for(0..256) |x| {
                self.frame_buffer[y][x].r = 0; 
                self.frame_buffer[y][x].g = 0; 
                self.frame_buffer[y][x].b = 0; 
                self.frame_buffer[y][x].a = 0xFF; 
            }
        }
    }

    pub fn render(self: *Video, screen: *const [6912]u8) void {
        //screen[0..6144]    = pixel bitmap
        //screen[6144..6912] = attributes (32x24)
        for(0..192) |y| {
            for(0..32) |x_byte| {
                const offset = resolve_address(@intCast(x_byte), @intCast(y));                 

                const bitmap_byte = screen[offset];
                 
                const attribute_byte = screen[6144 + (y >> 3) * 32 + x_byte]; 

                //0000 0000
                const bright = (attribute_byte & 0x40) >> 6; 
                const ink =  (attribute_byte & 0x07); 
                const paper = (attribute_byte & 0x38) >> 3;
                
                for(0..8) |bit| {
                    const x = x_byte * 8 + bit;
                    //test bit 7 - bit of the bitmap_byte
                    const shift: u3 = @intCast(7 - bit);
                    const on = (bitmap_byte >> (shift)) & 1; 

                    if(on != 0){
                        self.frame_buffer[y][x] = palette[bright * 8 + ink];
                    }else{
                        self.frame_buffer[y][x] = palette[bright * 8 + paper];
                    }
                }

                ////self.frame_buffer[y][x_byte] = palette[bright * 8 + color];
            } 
        }
    }
};

//returns an offset of the address, not the absolute address in memory. only from 0 to 0x17FF
pub fn resolve_address(x_byte: u16, y: u16) u16 {
    //easy part

    //64 is 2^6 
    const y_third = y >> 6;

    //1100 0000
    //0011 1111
    //
    const y_line = (y & 0x3F) >> 3;

    //0000 0111 
    const y_row = y & 0x07; 

    return (x_byte | y_row << 8 | y_line << 5 | y_third << 11);
}
