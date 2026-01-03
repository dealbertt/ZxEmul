const std = @import("std");

const hiResWidth: u8 = 256;
const hiResHeight: u8 = 192;

const loResWidth: u8 = 64;
const loResHeight: u8 = 32;

var gpx: [hiResWidth][hiResHeight]u8 = 0;
var keyPad: u8[40] = [_]u8{0} ** 40;

