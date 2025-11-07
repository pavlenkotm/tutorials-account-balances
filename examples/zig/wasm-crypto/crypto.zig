const std = @import("std");

/// Keccak256 implementation for WebAssembly
/// Demonstrates high-performance crypto in Zig

pub fn keccak256(input: []const u8) [32]u8 {
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha3.Keccak256.hash(input, &hash, .{});
    return hash;
}

pub fn hexEncode(bytes: []const u8, out: []u8) void {
    const hex_chars = "0123456789abcdef";
    for (bytes, 0..) |byte, i| {
        out[i * 2] = hex_chars[byte >> 4];
        out[i * 2 + 1] = hex_chars[byte & 0x0F];
    }
}

export fn hash_message(ptr: [*]const u8, len: usize) [32]u8 {
    const input = ptr[0..len];
    return keccak256(input);
}

pub fn main() !void {
    const message = "Hello, Zig + WASM!";
    const hash = keccak256(message);

    std.debug.print("Message: {s}\n", .{message});
    std.debug.print("Hash: ", .{});

    var hex: [64]u8 = undefined;
    hexEncode(&hash, &hex);
    std.debug.print("{s}\n", .{hex});
}
