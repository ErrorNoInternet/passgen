const std = @import("std");
const stdout = std.io.getStdOut().writer();

const BUFFER_SIZE = 8192;
const PREFIX_SIZE = 512;

var buffer: [BUFFER_SIZE]u8 = undefined;
var buffer_usage: usize = 0;

fn generate(
    keywords: [][]const u8,
    keyword_count: u8,
    keyword_lengths: *[64]u8,
    prefix: *[PREFIX_SIZE]u8,
    prefix_length: usize,
    level: u8,
) !void {
    if (buffer_usage >= BUFFER_SIZE - prefix_length) {
        _ = try stdout.writeAll(buffer[0..buffer_usage]);
        buffer_usage = 0;
    }
    if (level == 0) {
        prefix[prefix_length] = '\n';
        std.mem.copyForwards(u8, buffer[buffer_usage..], prefix[0 .. prefix_length + 1]);
        buffer_usage += prefix_length + 1;
    } else {
        var i: u8 = 0;
        while (i < keyword_count) : (i += 1) {
            const keyword_length = keyword_lengths[i];
            std.mem.copyForwards(u8, prefix[prefix_length..], keywords[i][0..keyword_length]);
            _ = try generate(keywords, keyword_count, keyword_lengths, prefix, prefix_length + keyword_length, level - 1);
        }
    }
}

fn calculateCombinations(n: u64, i: u32) u64 {
    if (i == 1) {
        return n;
    } else {
        return std.math.pow(u64, n, i) + calculateCombinations(n, i - 1);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var keywords = try std.ArrayList([]const u8).initCapacity(allocator, 64);
    defer keywords.deinit();

    var keyword_lengths: [64]u8 = undefined;
    var do_calculate_combinations = false;
    var keyword_count: u8 = 0;

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    var argc: u8 = 0;
    for (argv) |arg| {
        if (argc == 0) {
            argc += 1;
            continue;
        }

        if (std.mem.eql(u8, "-c", arg)) {
            do_calculate_combinations = true;
        } else {
            try keywords.append(arg);
            keyword_lengths[keyword_count] = @truncate(arg.len);
            keyword_count += 1;
        }
    }
    if (keyword_count == 0) {
        try stdout.print("no keywords specified!\n", .{});
        return;
    }

    if (do_calculate_combinations) {
        const lines = calculateCombinations(keyword_count, @as(u32, keyword_count)) + 1;
        var average_length: f64 = 0;
        for (keywords.items) |keyword| {
            average_length += @as(f64, @floatFromInt(keyword.len));
        }
        average_length /= @as(f64, @floatFromInt(keyword_count));
        var bytes: f64 = 1.0;
        var i: u32 = 1;
        while (i <= keyword_count) : (i += 1) {
            const ii = @as(f64, @floatFromInt(i));
            const currentLines = std.math.pow(f64, @as(f64, @floatFromInt(keyword_count)), ii);
            bytes += currentLines + currentLines * (average_length * ii);
        }
        try stdout.print("keywords: {}\n\nlines: {}\nbytes: {d}\n", .{ keyword_count, lines, bytes });
    } else {
        var prefix: [PREFIX_SIZE]u8 = undefined;
        for (0..keyword_count + 1) |i| {
            _ = try generate(keywords.items, keyword_count, &keyword_lengths, &prefix, 0, @truncate(i));
        }
    }
    if (buffer_usage > 0) {
        _ = try stdout.writeAll(buffer[0..buffer_usage]);
    }
}
