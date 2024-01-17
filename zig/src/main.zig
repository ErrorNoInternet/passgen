const std = @import("std");
const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();
const math = std.math;

const BUFFER_SIZE = 8192;
const PREFIX_SIZE = 512;

var buffer: [BUFFER_SIZE]u8 = undefined;
var bufferUsage: usize = 0;

fn generate(
    allocator: Allocator,
    keywords: [][]const u8,
    keywordCount: u8,
    keywordLengths: []const u8,
    prefix: *[PREFIX_SIZE]u8,
    prefixLength: usize,
    level: u8,
) !void {
    if (bufferUsage >= BUFFER_SIZE - prefixLength) {
        _ = try stdout.writeAll(buffer[0..bufferUsage]);
        bufferUsage = 0;
    }
    if (level == 0) {
        prefix[prefixLength] = '\n';
        std.mem.copy(u8, buffer[bufferUsage..], prefix[0 .. prefixLength + 1]);
        bufferUsage += prefixLength + 1;
    } else {
        var i: u8 = 0;
        while (i < keywordCount) : (i += 1) {
            const keywordLength = keywordLengths[i];
            std.mem.copy(u8, prefix[prefixLength..], keywords[i][0..keywordLength]);
            _ = try generate(allocator, keywords, keywordCount, keywordLengths, prefix, prefixLength + keywordLength, level - 1);
        }
    }
}

fn calculateCombinations(n: u64, i: u32) u64 {
    if (i == 1) {
        return n;
    } else {
        return math.pow(u64, n, i) + calculateCombinations(n, i - 1);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var keywords = try std.ArrayList([]const u8).initCapacity(allocator, 64);
    defer keywords.deinit();

    var keywordLengths: [64]u8 = undefined;
    var doCalculateCombinations = false;
    var keywordCount: u8 = 0;

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    var argc: u8 = 0;
    for (argv) |arg| {
        if (argc == 0) {
            argc += 1;
            continue;
        }

        if (std.mem.eql(u8, "-c", arg)) {
            doCalculateCombinations = true;
        } else {
            try keywords.append(arg);
            keywordLengths[keywordCount] = @truncate(arg.len);
            keywordCount += 1;
        }
    }
    if (keywordCount == 0) {
        try stdout.print("no keywords specified!\n", .{});
        return;
    }

    if (doCalculateCombinations) {
        const lines = calculateCombinations(keywordCount, @as(u32, keywordCount)) + 1;
        var averageLength: f64 = 0;
        for (keywords.items) |keyword| {
            averageLength += @as(f64, @floatFromInt(keyword.len));
        }
        averageLength /= @as(f64, @floatFromInt(keywordCount));
        var bytes: f64 = 1.0;
        var i: u32 = 1;
        while (i <= keywordCount) : (i += 1) {
            const ii = @as(f64, @floatFromInt(i));
            const currentLines = math.pow(f64, @as(f64, @floatFromInt(keywordCount)), ii);
            bytes += currentLines + currentLines * (averageLength * ii);
        }
        try stdout.print("keywords: {}\n\nlines: {}\nbytes: {d}\n", .{ keywordCount, lines, bytes });
    } else {
        var prefix: [PREFIX_SIZE]u8 = undefined;
        for (0..keywordCount + 1) |i| {
            _ = try generate(allocator, keywords.items, keywordCount, &keywordLengths, &prefix, 0, @truncate(i));
        }
    }
    if (bufferUsage > 0) {
        _ = try stdout.writeAll(buffer[0..bufferUsage]);
    }
}
