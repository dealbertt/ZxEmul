const std = @import("std");
const z = @import("../z80/z80.zig");

const ROM_MEMORY_LIMIT = 16384;

const hiResWidth: u8 = 256;
const hiResHeight: u8 = 192;

const loResWidth: u8 = 64;
const loResHeight: u8 = 32;

var gpx: [hiResWidth][hiResHeight]u8 = 0;
var keyPad: u8[40] = [_]u8{0} ** 40;

const memorySize: u32 = 65536;

pub const Spectrum = struct{
    memory: [memorySize] u8,
    cpu: z.Z80,

    pub fn init(path: []const u8) !Spectrum {
        var spec = Spectrum {
            .memory = [_]u8{0} ** memorySize,
            .cpu = undefined,
        };
        spec.cpu = z.Z80.init(spec.memory[0..]);
        _ = try spec.loadROM(path);

        return spec;
    }

    fn loadROM(self: *Spectrum, path: []const u8) !u8 {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();


        const rom_size = try file.getEndPos();
        std.debug.print("Size of the file: {}\n", .{rom_size});

        if(rom_size > ROM_MEMORY_LIMIT){
            std.debug.print("The size of the ROM selected is too big!", .{});
            return error.romSizeTooBig; 
        }

        const bytes_read = try file.read(&self.memory);


        std.debug.print("Bytes read: {}\n", .{bytes_read});
        return 0;
    }
};
