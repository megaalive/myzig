//! Living friction playbook loader — text first, code later.
//!
//! Package playbook: `docs/friction-playbook.md` (or `MYZIG_FRICTION_PLAYBOOK`).
//! Project overlay: `.myzig/friction-playbook.md` (optional, appended).

const std = @import("std");
const compat = @import("compat.zig");

/// Built-in stub so `myzig friction` still helps when no markdown file is nearby.
pub const embedded_playbook =
    \\# myzig friction playbook (embedded stub)
    \\
    \\No on-disk playbook was found next to the working directory.
    \\
    \\**do:** Add or vendor `docs/friction-playbook.md`, or set
    \\`MYZIG_FRICTION_PLAYBOOK`, or create `.myzig/friction-playbook.md`.
    \\Update those text files when you hit new agent friction — prefer text
    \\before new Zig rules.
    \\
    \\Also see: `myzig rules --agent`, `docs/agent-friction.md`.
    \\
;

pub const Layer = struct {
    label: []const u8,
    path: []const u8,
    body: []const u8,
};

pub const Bundle = struct {
    layers: std.ArrayList(Layer),
    /// Bodies allocated from `gpa` (not including embedded static).
    owned: std.ArrayList([]u8),

    pub fn deinit(self: *Bundle, gpa: std.mem.Allocator) void {
        for (self.owned.items) |b| gpa.free(b);
        self.owned.deinit(gpa);
        self.layers.deinit(gpa);
    }
};

pub fn load(io: compat.Io, gpa: std.mem.Allocator) !Bundle {
    var bundle = Bundle{
        .layers = .empty,
        .owned = .empty,
    };
    errdefer bundle.deinit(gpa);

    // 1) Env override for the package/canonical playbook.
    if (compat.envGet(gpa, "MYZIG_FRICTION_PLAYBOOK")) |env_path| {
        defer gpa.free(env_path);
        _ = try tryAppendFile(io, gpa, &bundle, "env:MYZIG_FRICTION_PLAYBOOK", env_path);
    } else |_| {}

    // 2) Package / checkout locations (first hit wins among these if env unset).
    const package_candidates = [_][]const u8{
        "docs/friction-playbook.md",
        "myzig/docs/friction-playbook.md",
    };
    var loaded_package = bundle.layers.items.len > 0;
    if (!loaded_package) {
        for (package_candidates) |cand| {
            if (try tryAppendFile(io, gpa, &bundle, "package", cand)) {
                loaded_package = true;
                break;
            }
        }
    }

    // 3) Project overlay — always try; appends after package layer.
    _ = try tryAppendFile(io, gpa, &bundle, "project-overlay", ".myzig/friction-playbook.md");

    if (bundle.layers.items.len == 0) {
        try bundle.layers.append(gpa, .{
            .label = "embedded",
            .path = "(builtin)",
            .body = embedded_playbook,
        });
    }

    return bundle;
}

fn tryAppendFile(
    io: compat.Io,
    gpa: std.mem.Allocator,
    bundle: *Bundle,
    label: []const u8,
    path: []const u8,
) !bool {
    const body = compat.readFileAlloc(io, gpa, path, 2 * 1024 * 1024) catch return false;
    errdefer gpa.free(body);
    try bundle.owned.append(gpa, body);
    try bundle.layers.append(gpa, .{
        .label = label,
        .path = path,
        .body = body,
    });
    return true;
}

pub fn write(writer: *std.Io.Writer, bundle: Bundle, show_sources: bool) std.Io.Writer.Error!void {
    if (show_sources) {
        try writer.writeAll("friction playbook sources:\n");
        for (bundle.layers.items) |layer| {
            try writer.print("  - [{s}] {s}\n", .{ layer.label, layer.path });
        }
        try writer.writeAll("\n");
    }
    for (bundle.layers.items, 0..) |layer, i| {
        if (bundle.layers.items.len > 1) {
            try writer.print("--- layer {d}: [{s}] {s} ---\n", .{ i + 1, layer.label, layer.path });
        }
        try writer.writeAll(layer.body);
        if (layer.body.len == 0 or layer.body[layer.body.len - 1] != '\n') {
            try writer.writeAll("\n");
        }
        if (i + 1 < bundle.layers.items.len) try writer.writeAll("\n");
    }
}

pub const AppendError = error{ EmptyNote, OutOfMemory } || compat.WriteError || compat.PathError || compat.ReadError;

/// Append a dated note to `.myzig/friction-playbook.md` (create overlay if missing).
pub fn appendNote(io: compat.Io, gpa: std.mem.Allocator, text: []const u8) AppendError![]const u8 {
    const path = ".myzig/friction-playbook.md";
    try compat.createDirPath(io, ".myzig");
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return error.EmptyNote;

    const existing = compat.readFileAlloc(io, gpa, path, 2 * 1024 * 1024) catch try gpa.dupe(u8,
        \\# Project friction overlay
        \\
        \\Notes captured with `myzig friction note` / `zrig friction note`.
        \\
    );
    defer gpa.free(existing);

    const block = try std.fmt.allocPrint(gpa,
        \\
        \\### note · agent
        \\- **capture:** {s}
        \\- **do:** Promote to F-* tip or incident when it repeats
        \\- **don't:** Leave only in chat memory
        \\
    , .{trimmed});
    defer gpa.free(block);

    const merged = try std.mem.concat(gpa, u8, &.{ existing, block });
    defer gpa.free(merged);
    try compat.writeFile(io, path, merged);
    return path;
}

test "embedded stub is non-empty" {
    try std.testing.expect(embedded_playbook.len > 40);
}
