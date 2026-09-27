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

    cpu.state.memory[0x0005] = 0xC9;
    cpu.state.memory[0x0005] = 0xC9;
    

}

fn handleArgs(init: std.process.Init) ![]const u8 {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if(args.len < 2) return "";

    //return try alloc.dupe(u8, args[1]);
    return args[1];
}
