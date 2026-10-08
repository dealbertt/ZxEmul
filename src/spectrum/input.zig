const std = @import("std");
const rl = @import("raylib");

/// Host key for each Spectrum key, indexed [row][bit] (bit 0 = outermost key of the half-row).
/// Caps Shift = left shift, Symbol Shift = right shift.
const key_map: [8][5]rl.KeyboardKey = .{
    .{ .left_shift, .z, .x, .c, .v },
    .{ .a, .s, .d, .f, .g },
    .{ .q, .w, .e, .r, .t },
    .{ .one, .two, .three, .four, .five },
    .{ .zero, .nine, .eight, .seven, .six },
    .{ .p, .o, .i, .u, .y },
    .{ .enter, .l, .k, .j, .h },
    .{ .space, .right_shift, .m, .n, .b },
};

pub fn update(matrix: *[8]u8) void {
    @memset(matrix[0..], 0xFF);
    for(key_map, 0..) |row_keys, row| {
        for(row_keys, 0..) |key, bit| {
            if(rl.isKeyDown(key)) {
                //the row contains the row of keys, where the first 5 bits correspond to a key
                //set the bit to 0,, reset it
                matrix[row] &= ~(@as(u8, 1) << @intCast(bit));   
            }
        }
    }
}
