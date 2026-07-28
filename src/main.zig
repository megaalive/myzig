const std = @import("std");
const Io = std.Io;
const myzig = @import("myzig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    var stdout_buffer: [8192]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_file_writer: Io.File.Writer = .init(.stderr(), io, &stderr_buffer);
    const stderr = &stderr_file_writer.interface;

    var argv = if (args.len > 0) args[1..] else args[0..0];
    // `zig build run -- -- check` and similar harnesses leave a leading `--`.
    while (argv.len > 0 and std.mem.eql(u8, argv[0], "--")) argv = argv[1..];

    const rio = myzig.cli.RunIo{
        .allocator = arena,
        .io = io,
        .stdout = stdout,
        .stderr = stderr,
        .version = myzig.version,
    };

    // Expected coach outcomes exit cleanly (no error-return stack traces).
    // Agents treat traces as crashes; findings/usage are normal control flow.
    myzig.cli.dispatch(rio, argv) catch |err| {
        try stdout.flush();
        switch (err) {
            error.Usage => {
                try stderr.writeAll("myzig: bad usage (try `myzig help`)\n");
                try stderr.flush();
                std.process.exit(2);
            },
            error.UnknownCommand => {
                try stderr.flush();
                std.process.exit(2);
            },
            error.Findings => {
                try stderr.flush();
                std.process.exit(1);
            },
            else => {
                try stderr.print("myzig: {s}\n", .{@errorName(err)});
                try stderr.flush();
                std.process.exit(1);
            },
        }
    };

    try stdout.flush();
    try stderr.flush();
}

test "cli module loads" {
    try std.testing.expect(myzig.cli.Command.parse("rules") == .rules);
}
