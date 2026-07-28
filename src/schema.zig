//! Core schemas for rules, obligations, certainty, and repairs.
//!
//! Heuristic detectors must set `certainty_ceiling` so the engine cannot
//! accidentally emit stronger claims than the detector can justify.

const std = @import("std");

pub const Certainty = enum {
    /// Expensive; only when local facts suffice. Heuristic AST rules must not use this as ceiling.
    proven,
    /// Default for early ownership analysis.
    likely,
    /// Style / API contracts.
    convention,

    pub fn asText(self: Certainty) []const u8 {
        return switch (self) {
            .proven => "proven",
            .likely => "likely",
            .convention => "convention",
        };
    }

    /// Returns true when `claim` is at or below `ceiling`.
    pub fn allows(ceiling: Certainty, claim: Certainty) bool {
        return @intFromEnum(claim) >= @intFromEnum(ceiling);
    }
};

pub const Severity = enum {
    error_,
    warning,
    note,

    pub fn asText(self: Severity) []const u8 {
        return switch (self) {
            .error_ => "error",
            .warning => "warning",
            .note => "note",
        };
    }
};

pub const Category = enum {
    ownership,
    allocator,
    unsafe_accounting,
    lifetime,
    ffi,
    other,

    pub fn asText(self: Category) []const u8 {
        return switch (self) {
            .ownership => "ownership",
            .allocator => "allocator",
            .unsafe_accounting => "unsafe_accounting",
            .lifetime => "lifetime",
            .ffi => "ffi",
            .other => "other",
        };
    }
};

pub const ObligationKind = enum {
    memory_must_release_or_transfer,
    resource_must_close_or_transfer,
    unsafe_must_be_permitted,
    external_ownership_must_be_documented,
    other,

    pub fn asText(self: ObligationKind) []const u8 {
        return switch (self) {
            .memory_must_release_or_transfer => "memory_must_release_or_transfer",
            .resource_must_close_or_transfer => "resource_must_close_or_transfer",
            .unsafe_must_be_permitted => "unsafe_must_be_permitted",
            .external_ownership_must_be_documented => "external_ownership_must_be_documented",
            .other => "other",
        };
    }
};

pub const DischargeKind = enum {
    free,
    destroy,
    deinit,
    defer_free,
    errdefer_free,
    transfer_return,
    transfer_out_param,
    arena_scoped,
    permit,
    documented_external,
    other,

    pub fn asText(self: DischargeKind) []const u8 {
        return switch (self) {
            .free => "free",
            .destroy => "destroy",
            .deinit => "deinit",
            .defer_free => "defer_free",
            .errdefer_free => "errdefer_free",
            .transfer_return => "transfer_return",
            .transfer_out_param => "transfer_out_param",
            .arena_scoped => "arena_scoped",
            .permit => "permit",
            .documented_external => "documented_external",
            .other => "other",
        };
    }
};

pub const DetectorKind = enum {
    local_ast,
    intraprocedural,
    path_sensitive,
    external_observation,
    other,

    pub fn asText(self: DetectorKind) []const u8 {
        return switch (self) {
            .local_ast => "local_ast",
            .intraprocedural => "intraprocedural",
            .path_sensitive => "path_sensitive",
            .external_observation => "external_observation",
            .other => "other",
        };
    }
};

/// Ownership fixes need intent. myzig offers choices; it must not silently invent policy.
pub const RepairTier = enum {
    /// Human/agent chooses among options.
    suggestion,
    /// Documented preferred form for a known intent.
    canonical,
    /// Only when preconditions leave no intent ambiguity.
    automatic,

    pub fn asText(self: RepairTier) []const u8 {
        return switch (self) {
            .suggestion => "suggestion",
            .canonical => "canonical",
            .automatic => "automatic",
        };
    }
};

pub const Repair = struct {
    tier: RepairTier,
    intent: []const u8,
    summary: []const u8,
};

pub const Rule = struct {
    id: []const u8,
    category: Category,
    default_severity: Severity,
    certainty_ceiling: Certainty,
    obligation: ObligationKind,
    detector: DetectorKind,
    discharges: []const DischargeKind,
    message: []const u8,
    explanation: []const u8,
    repairs: []const Repair,
    references: []const []const u8,

    /// Clamp an emitted certainty so it never exceeds this rule's ceiling.
    pub fn clampCertainty(self: Rule, claim: Certainty) Certainty {
        if (Certainty.allows(self.certainty_ceiling, claim)) return claim;
        return self.certainty_ceiling;
    }
};

/// Placeholder seed rule for M0/M1 scaffolding — not yet backed by a detector.
pub const seed_alloc_undischarged: Rule = .{
    .id = "memory.alloc-undischarged",
    .category = .allocator,
    .default_severity = .warning,
    .certainty_ceiling = .likely,
    .obligation = .memory_must_release_or_transfer,
    .detector = .local_ast,
    .discharges = &.{
        .free,
        .destroy,
        .deinit,
        .defer_free,
        .errdefer_free,
        .transfer_return,
        .transfer_out_param,
        .arena_scoped,
    },
    .message = "allocated memory may leave the function without release or transfer",
    .explanation =
    \\An allocation creates an ownership obligation: the memory must be
    \\released, destroyed, deinited, or explicitly transferred. Early myzig
    \\analysis is local and reports this as `likely`, not `proven`.
    ,
    .repairs = &.{
        .{
            .tier = .suggestion,
            .intent = "local_lifetime",
            .summary = "Add `defer allocator.free(buffer);` when the buffer stays local.",
        },
        .{
            .tier = .suggestion,
            .intent = "error_only_cleanup",
            .summary = "Use `errdefer` when success paths transfer ownership to the caller.",
        },
        .{
            .tier = .canonical,
            .intent = "local_lifetime",
            .summary = "Prefer `defer` free for straight-line local buffers with no transfer.",
        },
    },
    .references = &.{
        "fixtures/fail/alloc_undischarged.zig",
        "fixtures/pass/alloc_defer_free.zig",
        "research/incidents/MYZIG-OWN-001.md",
    },
};

pub const seed_file_undischarged: Rule = .{
    .id = "resource.file-undischarged",
    .category = .ownership,
    .default_severity = .warning,
    .certainty_ceiling = .likely,
    .obligation = .resource_must_close_or_transfer,
    .detector = .local_ast,
    .discharges = &.{ .defer_free, .other },
    .message = "opened/created file may leave the function without close",
    .explanation =
    \\Opening a file acquires a resource obligation: close it, defer-close it,
    \\or transfer the handle. Local heuristics look for `.close` discharge markers.
    ,
    .repairs = &.{
        .{
            .tier = .canonical,
            .intent = "local_lifetime",
            .summary = "Add `defer file.close(...);` immediately after a successful open.",
        },
        .{
            .tier = .suggestion,
            .intent = "transfer_return",
            .summary = "Return the file handle to the caller and document ownership transfer.",
        },
    },
    .references = &.{
        "fixtures/fail/file_undischarged.zig",
        "fixtures/pass/file_defer_close.zig",
    },
};

pub const seed_ptrcast_unremarked: Rule = .{
    .id = "unsafe.ptrcast-unremarked",
    .category = .unsafe_accounting,
    .default_severity = .note,
    .certainty_ceiling = .convention,
    .obligation = .unsafe_must_be_permitted,
    .detector = .local_ast,
    .discharges = &.{.permit},
    .message = "pointer cast lacks an adjacent safety/permit remark",
    .explanation =
    \\`@ptrCast` / `@alignCast` are explicit unsafe operations. Early myzig asks
    \\for an adjacent `// safety:` or permit remark so the reason stays auditable.
    \\This is a convention signal, not a proof of undefined behavior.
    ,
    .repairs = &.{
        .{
            .tier = .suggestion,
            .intent = "document_unsafe",
            .summary = "Add `// safety: <reason>` on the cast line, or a future `unsafe.permit` form.",
        },
    },
    .references = &.{
        "fixtures/fail/ptrcast_unremarked.zig",
        "fixtures/pass/ptrcast_remarked.zig",
    },
};

pub const seed_rules: []const Rule = &.{
    seed_alloc_undischarged,
    seed_file_undischarged,
    seed_ptrcast_unremarked,
};

test "certainty ceiling clamps proven down to likely" {
    const clamped = seed_alloc_undischarged.clampCertainty(.proven);
    try std.testing.expect(clamped == .likely);
}

test "certainty allows equal or weaker claims" {
    try std.testing.expect(Certainty.allows(.likely, .likely));
    try std.testing.expect(Certainty.allows(.likely, .convention));
    try std.testing.expect(!Certainty.allows(.likely, .proven));
}

test "seed rule id is stable" {
    try std.testing.expectEqualStrings("memory.alloc-undischarged", seed_alloc_undischarged.id);
}
