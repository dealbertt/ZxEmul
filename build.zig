const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    const mod = b.addModule("ZxEmul", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    const z80_mod = b.createModule(.{
        .root_source_file = b.path("src/z80/z80.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ZxEmul",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ZxEmul", .module = mod },
            },
        }),
    });

    const zex_test = b.addExecutable(.{
        .name = "test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/main.zig"),
            .target = target,
            .optimize = .ReleaseFast,
            .imports = &.{
                .{.name = "z80", .module = z80_mod}
            },
        }),
    });
    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);


    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    //zexdoc runner: not installed, so it's only compiled when this step is asked for (zig build zexdoc).
    //addFileArg passes the full path to the .com and lets the build track it as an input
    const zex_cmd = b.addRunArtifact(zex_test);
    zex_cmd.addFileArg(b.path("programs/zexdoc.com"));

    const zex_step = b.step("zexdoc", "Run the zexdoc Z80 instruction test");
    zex_step.dependOn(&zex_cmd.step);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

}
