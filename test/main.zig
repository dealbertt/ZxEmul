const std = @import("std");


const z80 = @import("z80");
pub fn main(init: std.process.Init) void {
    _ = init;
    std.debug.print("Hello test!\n", .{});

}
