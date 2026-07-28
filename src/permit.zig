//! Permit kinds for explicit unsafe accounting (`myzig.permit` / `unsafe.permit`).

const std = @import("std");

/// Granular permit kinds agents/humans must name when discharging unsafe ops.
pub const Kind = enum {
    ptrcast,
    aligncast,
    bitcast,
    ffi,
    other,

    pub fn asText(self: Kind) []const u8 {
        return switch (self) {
            .ptrcast => "ptrcast",
            .aligncast => "aligncast",
            .bitcast => "bitcast",
            .ffi => "ffi",
            .other => "other",
        };
    }

    pub fn parse(name: []const u8) ?Kind {
        if (std.mem.eql(u8, name, "ptrcast")) return .ptrcast;
        if (std.mem.eql(u8, name, "aligncast")) return .aligncast;
        if (std.mem.eql(u8, name, "bitcast")) return .bitcast;
        if (std.mem.eql(u8, name, "ffi")) return .ffi;
        if (std.mem.eql(u8, name, "other")) return .other;
        return null;
    }

    /// Kind expected for a cast needle on the same line.
    pub fn forNeedle(needle: []const u8) Kind {
        if (std.mem.eql(u8, needle, "@ptrCast(")) return .ptrcast;
        if (std.mem.eql(u8, needle, "@alignCast(")) return .aligncast;
        if (std.mem.eql(u8, needle, "@bitCast(")) return .bitcast;
        return .other;
    }
};

pub const LinePermit = struct {
    /// True when a safety/permit remark discharges the site.
    ok: bool,
    /// True when `myzig.permit(kind)` / `unsafe.permit(kind)` was used.
    structured: bool = false,
    kind: ?Kind = null,
};

/// Accept:
/// - `// safety: …`
/// - `// myzig.permit` / `// unsafe.permit` (legacy unstructured)
/// - `// myzig.permit(ptrcast): reason` / `unsafe.permit(aligncast): …`
pub fn parseLine(line: []const u8, expected: Kind) LinePermit {
    if (std.mem.indexOf(u8, line, "safety:") != null) {
        return .{ .ok = true, .structured = false, .kind = null };
    }

    const markers = [_][]const u8{ "myzig.permit", "unsafe.permit" };
    for (markers) |marker| {
        if (std.mem.indexOf(u8, line, marker)) |at| {
            const after = line[at + marker.len ..];
            if (after.len > 0 and after[0] == '(') {
                const close = std.mem.indexOfScalar(u8, after, ')') orelse return .{ .ok = false };
                const name = std.mem.trim(u8, after[1..close], " \t");
                const kind = Kind.parse(name) orelse return .{ .ok = false };
                // Structured permit must match the operation kind (ffi/other are wildcards).
                const matches = kind == expected or kind == .ffi or kind == .other;
                return .{ .ok = matches, .structured = true, .kind = kind };
            }
            // Unstructured permit still discharges (migration path).
            return .{ .ok = true, .structured = false, .kind = null };
        }
    }
    return .{ .ok = false };
}

test "structured permit matches kind" {
    const ok = parseLine("return @ptrCast(p); // myzig.permit(ptrcast): FFI", .ptrcast);
    try std.testing.expect(ok.ok and ok.structured);
    const bad = parseLine("return @ptrCast(p); // myzig.permit(bitcast): nope", .ptrcast);
    try std.testing.expect(!bad.ok);
    const safety = parseLine("return @ptrCast(p); // safety: opaque", .ptrcast);
    try std.testing.expect(safety.ok);
}
