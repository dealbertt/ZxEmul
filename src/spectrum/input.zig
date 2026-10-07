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

pub const Keyboard = struct {
    rows: [8]u8,
    
    pub fn init(self: *Keyboard) void {
        self.rows = [_]u8 {0xFF} ** 8;
    }

    pub fn update(self: *Keyboard) void {
        // TODO(human): reset all rows to 0xFF, then clear the bit of every key that rl.isKeyDown reports as pressed.
        //reset all the rows
        @memset(self.rows[0..], 0xFF);

        for(self.rows) |row| {
            _ = row;
        }
    }
};
