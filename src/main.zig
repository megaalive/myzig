const std = @import("std");
const Io = std.Io;
const myzig = @import("myzig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_file_writer: Io.File.Writer = .init(.stderr(), io, &stderr_buffer);
    const stderr = &stderr_file_writer.interface;

    // args[0] is the executable path when present.
    const argv = if (args.len > 0) args[1..] else args[0..0];
    const command: myzig.cli.Command = if (argv.len == 0) .help else myzig.cli.Command.parse(argv[0]);

    switch (command) {
        .help => {
            try myzig.cli.writeHelp(stdout);
            try stdout.flush();
        },
        .version => {
            try myzig.cli.writeVersion(stdout, myzig.version);
            try stdout.flush();
        },
        .rules => {
            try myzig.cli.writeRulesText(stdout);
            try stdout.flush();
        },
        .unknown => {
            try stderr.print("myzig: unknown command '{s}'\n\n", .{argv[0]});
            try myzig.cli.writeHelp(stderr);
            try stderr.flush();
            return error.UnknownCommand;
        },
        else => {
            try stdout.print("{s}\n", .{myzig.cli.stubMessage(command)});
            try stdout.flush();
        },
    }
}

test "cli module loads" {
    try std.testing.expect(myzig.cli.Command.parse("rules") == .rules);
}
