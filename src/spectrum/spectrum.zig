const std = @import("std");
const z = @import("../z80/z80.zig");
const z80 = z.Z80;
const rl = @import("raylib");

const ROM_MEMORY_LIMIT = 16384;

const CYCLES_PER_REFRESH = 69888;

const FREQ = 3500000;

const hiResWidth: u8 = 256;
const hiResHeight: u8 = 192;

const loResWidth: u8 = 64;
const loResHeight: u8 = 32;

var gpx: [hiResWidth][hiResHeight]u8 = 0;
var keyPad: u8[40] = [_]u8{0} ** 40;

const memorySize: u32 = 65536;

pub const Spectrum = struct{
    memory: [memorySize] u8,
    cpu: z80,

    cycles: u32,
    pub fn init(self: *Spectrum, path: []const u8, init_proc: std.process.Init) !void {
        //var spec = Spectrum {
            //initialize the memory to 0
            //.memory = [_]u8{0} ** memorySize,
            //.cpu = undefined,
        //};

        self.memory = [_]u8{0} ** memorySize;
        //initialize the cpu
        self.cpu = z80.init(self.memory[0..]);

        _ = try self.loadROM(path, init_proc);
    }

    fn loadROM(self: *Spectrum, path: []const u8, init_proc: std.process.Init) !u8 {

        const io = init_proc.io;
        const file = try std.Io.Dir.cwd().openFile(io, path, .{.mode = .read_only});
        defer file.close(io);

        const rom_size = try file.length(io);
        std.debug.print("Size of the file: {}\n", .{rom_size});

        if(rom_size > ROM_MEMORY_LIMIT){
            std.debug.print("The size of the ROM selected is too big!", .{});
            return error.romSizeTooBig; 
        }

        var reader = file.reader(io, &self.memory);

        const bytes_read = try reader.interface.readSliceShort(&self.memory);
        //const bytes_read = try file.read(&self.memory);


        std.debug.print("Bytes read: {}\n", .{bytes_read});
        return 0;
    }

    //this will run ~70k cycles of z80 per frame 
    //50 frames/refresh per second -> total of 3.500.000 cycles per second
    //how am i going to get that? 
    pub fn runFrame(self: *Spectrum) void {
        var statesInFrame: u32 = 0;
        while(statesInFrame < CYCLES_PER_REFRESH){
            const cycles = self.cpu.cycle();
            statesInFrame += cycles;
        }
    }
};
