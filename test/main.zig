const std = @import("std");
const z = @import("z80");
pub fn main(init: std.process.Init) !void {
    var cpu: z.Z80 = undefined;

    cpu.init();
    cpu.state.bus.rom_protected = false;
    std.debug.print("Hello test!\n", .{});


    const program_path =  try handleArgs(init);


    const io = init.io;
    const file = try std.Io.Dir.cwd().openFile(io, program_path, .{.mode = .read_only});
    defer file.close(io);

    const rom_size = try file.length(io);
    std.debug.print("Size of the rom: {x}\n", .{rom_size});


    var scratch: [4096]u8 = undefined;
    var reader = file.reader(io, &scratch);

    const bytes_read = try reader.interface.readSliceShort(cpu.state.bus.memory[0x0100..0x0100 + rom_size]);
    //const bytes_read = try file.read(&self.memory);


    std.debug.print("Bytes read: {}\n", .{bytes_read});

    cpu.state.pc = 0x0100;
    //ret
    cpu.state.bus.memory[0x0005] = 0xC9;

    //top of the stack as a little-endian address: zexdoc does LD HL,(0x0006) / LD SP,HL
    cpu.state.bus.memory[0x0006] = 0x00;
    cpu.state.bus.memory[0x0007] = 0xF0;

    //the program ends by jumping to 0x0000 (CP/M warm boot)
    while(cpu.state.pc != 0x0000){
        //PC is checked before each instruction: at 0x0005 the program has just done CALL 5,
        //so the call is handled here and then the RET at 0x0005 runs and returns to the program
        if(cpu.state.pc == 0x0005) bdosCall(&cpu);
        _ = cpu.cycle();
    }
    std.debug.print("\nProgram finished\n", .{});
}

fn bdosCall(cpu: *z.Z80) void {
    const state = &cpu.state;

    //check the state of C
    switch(state.bc.bytes.lo){
        //print the character in E
        2 => std.debug.print("{c}", .{state.de.bytes.lo}),
        //print the string at DE, terminated by '$'
        9 => {
            var address = state.de.pair;
            while(state.bus.memory[address] != '$') : (address +%= 1) {
                std.debug.print("{c}", .{state.bus.memory[address]});
            }
        },
        else => std.debug.print("\n[unsupported BDOS function {}]\n", .{state.bc.bytes.lo}),
    }
}

fn handleArgs(init: std.process.Init) ![]const u8 {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if(args.len < 2) return "";

    //return try alloc.dupe(u8, args[1]);
    return args[1];
}
