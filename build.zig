const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module
    const tapsilat_mod = b.addModule("tapsilat", .{
        .root_source_file = b.path("src/tapsilat.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Library artifact (static)
    const lib = b.addLibrary(.{
        .name = "tapsilat",
        .linkage = .static,
        .root_module = tapsilat_mod,
    });
    b.installArtifact(lib);

    // Example executable
    const example_module = b.createModule(.{
        .root_source_file = b.path("examples/create_order.zig"),
        .target = target,
        .optimize = optimize,
    });

    example_module.addImport("tapsilat", tapsilat_mod);

    const example = b.addExecutable(.{
        .name = "tapsilat-example",
        .root_module = example_module,
    });
    b.installArtifact(example);

    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(b.getInstallStep());

    const example_step = b.step("example", "Run the create_order example");
    example_step.dependOn(&run_example.step);

    // Tests
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tapsilat.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib_tests = b.addTest(.{
        .root_module = test_module,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);
}
