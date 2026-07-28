//! Pass fixture: method `.create(value, …)` is not allocator.create(T).

const Context = struct {
    fn create(handle: *Handle, allocator: anytype) !Value {
        _ = handle;
        _ = allocator;
        return .{};
    }
};
const Handle = struct {};
const Value = struct {};
const Lazy = struct { value: ?Value = null };

pub fn lazyGet(lazy: *Lazy, handle: *Handle, allocator: anytype) !void {
    lazy.value = try Context.create(handle, allocator);
}
