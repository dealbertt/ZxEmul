const std = @import("std");
const z = @import("../z80/z80.zig");
const z80 = z.Z80;
const rl = @import("raylib");

const v = @import("video.zig");

const ROM_MEMORY_LIMIT = 16384;
const PROGRAM_MEMORY_LIMIT = 41781;

const CYCLES_PER_REFRESH = 69888;

//how long the ULA holds the interrupt line low at the start of each frame
const INT_HOLD_STATES = 32;

const FREQ = 3500000;

const memorySize: u32 = 65536;

const File_Fmt= enum {
    sna, z80, tap, tzx, unknown    
};

pub const Spectrum = struct{
    cpu: z80,
    cycles: u32,
    video: v.Video,

    //leaves the machine in its power-on state: cpu reset, ROM loaded, video ready.
    //loading a program is a separate step (loadProgram), done on the machine after this
    pub fn init(self: *Spectrum, init_proc: std.process.Init) !void {
        //var spec = Spectrum {
            //initialize the memory to 0
            //.memory = [_]u8{0} ** memorySize,
            //.cpu = undefined,
        //};

        //initialize the cpu
        self.cpu.init();
        _ = try self.loadROM(init_proc);

        self.video.init();
    }

    fn loadROM(self: *Spectrum, init_proc: std.process.Init) !u8 {

        const io = init_proc.io;
        const file = try std.Io.Dir.cwd().openFile(io, "assets/spec48.rom", .{.mode = .read_only});
        defer file.close(io);

        const rom_size = try file.length(io);
        std.debug.print("Size of the rom: {x}\n", .{rom_size});

        if(rom_size > ROM_MEMORY_LIMIT){
            std.debug.print("The size of the ROM selected is too big!", .{});
            return error.romSizeTooBig; 
        }

        var scratch: [4096]u8 = undefined;
        var reader = file.reader(io, &scratch);

        const bytes_read = try reader.interface.readSliceShort(self.cpu.state.bus.memory[0..rom_size]);
        //const bytes_read = try file.read(&self.memory);


        std.debug.print("Bytes read: {}\n", .{bytes_read});
        return 0;
    }

    pub fn loadProgram(self: *Spectrum, path: []const u8, init_proc: std.process.Init) !u8 {
        const fmt:File_Fmt = detectFormat(path);
        switch (fmt) {
            .sna => std.debug.print("SNAPSHOT\n", .{}),
        }
        const io = init_proc.io;
        const file = try std.Io.Dir.cwd().openFile(io, path, .{.mode = .read_only});
        defer file.close(io);

        const program_size = try file.length(io);
        std.debug.print("Size of the user program: {x}\n", .{program_size});

        if(program_size > PROGRAM_MEMORY_LIMIT){
            std.debug.print("The size of the program selected is too big!", .{});
            return error.programSizeTooBig; 
        }

        var scratch: [4096]u8 = undefined;
        var reader = file.reader(io, &scratch);

        const bytes_read = try reader.interface.readSliceShort(self.cpu.state.bus.memory[0x5CCB .. 0x5CCB + program_size]);
        //const bytes_read = try file.read(&self.memory);


        std.debug.print("Bytes read: {}\n", .{bytes_read});
        return 0;
    }


    //this will run ~70k cycles of z80 per frame 
    //50 frames/refresh per second -> total of 3.500.000 cycles per second
    //how am i going to get that? 
    pub fn runFrame(self: *Spectrum) void {
        //the ULA asserts the interrupt line once at the start of every frame (50Hz).
        //the cpu picks it up at its next instruction boundary, if interrupts are enabled
        self.cpu.state.bus.int_req = true;

        var statesInFrame: u32 = 0;
        while(statesInFrame < CYCLES_PER_REFRESH){
            const cycles = self.cpu.cycle();
            statesInFrame += cycles;

            //the line is only held low for a short window: code that stays with interrupts
            //disabled through it misses this frame's interrupt instead of getting it late
            if(statesInFrame >= INT_HOLD_STATES) self.cpu.state.bus.int_req = false;
        }
        self.video.render(self.cpu.state.bus.memory[0x4000..0x5B00]);
    }
};

fn detectFormat(path: [] const u8) File_Fmt{
    const ext = std.fs.path.extension(path);
    std.debug.print("Extension: {s}\n", .{ext});

    if(std.mem.eql(u8, ".sna", ext)){
        return .sna;
    }else if(std.mem.eql(u8, ".z80", ext)){
        return .z80;
    }else if(std.mem.eql(u8, ".tap", ext)){
        return .tap;
    }else if(std.mem.eql(u8, ".tzx", ext)){
        return .tzx;
    }else {
        return .unknown;
    }
}
