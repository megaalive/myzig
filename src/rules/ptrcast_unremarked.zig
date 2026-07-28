//! Convention detector for `unsafe.ptrcast-unremarked`.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const needles = [_][]const u8{ "@ptrCast(", "@alignCast(" };

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var search_from: usize = 0;
    while (search_from < source.len) {
        const hit = scan.nextNeedle(source, search_from, &needles) orelse break;
        const line = scan.lineSlice(source, hit);
        const remarked = std.mem.indexOf(u8, line, "safety:") != null or
            std.mem.indexOf(u8, line, "myzig.permit") != null or
            std.mem.indexOf(u8, line, "unsafe.permit") != null;
        if (!remarked) {
            try out.append(gpa, diagnostic.Diagnostic.fromRule(
                schema.seed_ptrcast_unremarked,
                .convention,
                .{
                    .path = path,
                    .line = scan.lineNumber(source, hit),
                    .column = scan.columnNumber(source, hit),
                },
                null,
            ));
        }
        search_from = hit + 1;
    }
}

test "ptrCast without remark is flagged" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad(p: *anyopaque) *u8 {
        \\    return @ptrCast(p);
        \\}
    ;
    const pass_src =
        \\pub fn ok(p: *anyopaque) *u8 {
        \\    return @ptrCast(p); // safety: FFI opaque handle
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expect(fail_diags.items.len >= 1);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);
}
