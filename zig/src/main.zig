const std = @import("std");

const BUFFER_SIZE = 8192;
const PREFIX_SIZE = 512;

var buf: [BUFFER_SIZE]u8 = undefined;
var buf_len: usize = 0;

var stdout_buf: [BUFFER_SIZE]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
const stdout = &stdout_writer.interface;

fn generate(
    keywords: [][]const u8,
    keyword_count: u8,
    keyword_lengths: *[64]u8,
    prefix: *[PREFIX_SIZE]u8,
    prefix_len: usize,
    level: u8,
) !void {
    if (buf_len >= BUFFER_SIZE - prefix_len) {
        _ = try stdout.writeAll(buf[0..buf_len]);
        buf_len = 0;
    }
    if (level == 0) {
        prefix[prefix_len] = '\n';
        std.mem.copyForwards(u8, buf[buf_len..], prefix[0 .. prefix_len + 1]);
        buf_len += prefix_len + 1;
    } else {
        var i: u8 = 0;
        while (i < keyword_count) : (i += 1) {
            const keyword_len = keyword_lengths[i];
            std.mem.copyForwards(u8, prefix[prefix_len..], keywords[i][0..keyword_len]);
            _ = try generate(keywords, keyword_count, keyword_lengths, prefix, prefix_len + keyword_len, level - 1);
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
    defer keywords.deinit(allocator);

    var keyword_lengths: [64]u8 = undefined;
    var do_calculate_combinations = false;
    var keyword_count: u8 = 0;

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    var argc: u8 = 0;
    for (argv) |arg| {
        argc += 1;
        if (argc == 1) {
            continue;
        }

        if (std.mem.eql(u8, "-c", arg)) {
            do_calculate_combinations = true;
        } else {
            try keywords.append(allocator, arg);
            keyword_lengths[keyword_count] = @truncate(arg.len);
            keyword_count += 1;
        }
    }

    if (keyword_count == 0) {
        try stdout.print("no keywords specified!\n", .{});
        try stdout.flush();
        return;
    }

    if (do_calculate_combinations) {
        const lines = calculateCombinations(keyword_count, @as(u32, keyword_count)) + 1;
        var avg_len: f64 = 0;
        for (keywords.items) |keyword| {
            avg_len += @as(f64, @floatFromInt(keyword.len));
        }
        avg_len /= @as(f64, @floatFromInt(keyword_count));
        var bytes: f64 = 1.0;
        var i: u32 = 1;
        while (i <= keyword_count) : (i += 1) {
            const ii = @as(f64, @floatFromInt(i));
            const cur_lines = std.math.pow(f64, @as(f64, @floatFromInt(keyword_count)), ii);
            bytes += cur_lines + cur_lines * (avg_len * ii);
        }

        try stdout.print("keywords: {}\n\nlines: {}\nbytes: {d}\n", .{ keyword_count, lines, bytes });
        try stdout.flush();
        return;
    }

    var prefix: [PREFIX_SIZE]u8 = undefined;
    for (0..keyword_count + 1) |i| {
        _ = try generate(keywords.items, keyword_count, &keyword_lengths, &prefix, 0, @truncate(i));
    }

    if (buf_len > 0) {
        try stdout.writeAll(buf[0..buf_len]);
        try stdout.flush();
    }
}
