const std = @import("std");

const screenWidth: u8 = 256;
const screenHeight: u8 = 192;

var gpx: [screenWidth][screenHeight]u8 = 0;
var keyPad: u8[40] = [_]u8{0} ** 40;

