const std = @import("std");
const DynamicArray = @import("./dynamic_array.zig").DynamicArray;
const Value = @import("./value.zig").Value;

const Allocator = std.mem.Allocator;

const expect = std.testing.expect;

pub const OpCode = enum(u8) {
    const Self = @This();

    op_ret,
    op_constant,
    op_negate,
    op_add,
    op_sub,
    op_mul,
    op_div,

    pub fn toU8(self: Self) u8 {
        return @enumToInt(self);
    }

    pub fn num_operands(self: Self) usize {
        return switch (self) {
            .op_constant => 1,
            else => 0,
        };
    }
};

pub const Chunk = struct {
    const Self = @This();
    const BytesArray = DynamicArray(u8);
    const ValuesArray = DynamicArray(Value);
    const LinesArray = DynamicArray(usize);

    code: BytesArray,
    constants: ValuesArray,
    lines: LinesArray,

    pub fn init(allocator: *Allocator) Chunk {
        return Self{
            .code = BytesArray.init(allocator),
            .constants = ValuesArray.init(allocator),
            .lines = LinesArray.init(allocator),
        };
    }

    pub fn write(self: *Self, byte: u8, line: usize) !void {
        try self.code.append_item(byte);
        try self.lines.append_item(line);
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn addConstant(self: *Self, value: Value) !u16 {
        try self.constants.append_item(value);
        return @intCast(u16, self.constants.count - 1);
    }
};

test "create a Chunk" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("The list is leaking");
    }

    var chunk = Chunk.init(&gpa.allocator);
    defer chunk.deinit();

    try chunk.write(OpCode.op_ret);
    try expect(chunk.code.items[0] == OpCode.op_ret);

    try chunk.write(OpCode.op_ret);
    try chunk.write(OpCode.op_ret);
    try chunk.write(OpCode.op_ret);
    try chunk.write(OpCode.op_ret);
    try chunk.write(OpCode.op_ret);

    try expect(chunk.code.items[4] == OpCode.op_ret);
    chunk.deinit();
}
