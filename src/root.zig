//! myzig — ownership reasoning and evidence protocol for Zig.
//!
//! Ordinary Zig is first-class: correct code can pass without importing this
//! package. Public surface starts with schemas; analysis grows from real
//! incidents, not a theoretical checklist.

const std = @import("std");

pub const schema = @import("schema.zig");
pub const diagnostic = @import("diagnostic.zig");
pub const catalog = @import("catalog.zig");
pub const scan = @import("scan.zig");
pub const check = @import("check.zig");
pub const explain = @import("explain.zig");
pub const receipt = @import("receipt.zig");
pub const cli = @import("cli.zig");
pub const compat = @import("compat.zig");
pub const friction = @import("friction.zig");
pub const baseline = @import("baseline.zig");
pub const adopt = @import("adopt.zig");
pub const json_out = @import("json_out.zig");

pub const Certainty = schema.Certainty;
pub const Severity = schema.Severity;
pub const Category = schema.Category;
pub const ObligationKind = schema.ObligationKind;
pub const DischargeKind = schema.DischargeKind;
pub const DetectorKind = schema.DetectorKind;
pub const RepairTier = schema.RepairTier;
pub const Repair = schema.Repair;
pub const Rule = schema.Rule;
pub const Diagnostic = diagnostic.Diagnostic;
pub const Location = diagnostic.Location;

/// Package identity shown by `myzig --version` and receipts.
pub const version: []const u8 = "0.0.0";

test {
    _ = schema;
    _ = diagnostic;
    _ = catalog;
    _ = scan;
    _ = check;
    _ = explain;
    _ = receipt;
    _ = cli;
    _ = compat;
    _ = friction;
    _ = baseline;
    _ = adopt;
    _ = json_out;
}
