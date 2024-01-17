const std = @import("std");

pub fn calculate_combinations(n: u128, i: u8) u128 {
    if (i == 1) {
        return n;
    } else {
        return std.math.pow(u128, n, i) + calculate_combinations(n, i - 1);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    var argc: u8 = 0;

    var calculate_size = false;
    var keyword_count: u8 = 0;
    var keywords: [256][]u8 = undefined;
    for (argv) |arg| {
        argc += 1;
        if (argc == 1) {
            continue;
        }

        if (std.mem.eql(u8, arg, "-c")) {
            calculate_size = true;
        } else {
            keywords[keyword_count] = arg;
            keyword_count += 1;
        }
    }
    if (keyword_count == 0) {
        std.debug.print("no keywords supplied!\n", .{});
        std.os.exit(1);
    }

    if (calculate_size) {
        const lines = 1 + calculate_combinations(keyword_count, keyword_count);
        var length_sum: u16 = 0;
        for (0..keyword_count) |ki| {
            length_sum += @truncate(keywords[ki].len);
        }
        const average_length: f64 = @as(f64, @floatFromInt(length_sum)) / @as(f64, @floatFromInt(keyword_count));
        var bytes: f64 = 1.0;
        for (1..keyword_count + 1) |i| {
            const ii = @as(f64, @floatFromInt(i));
            const level_lines = std.math.pow(f64, @as(f64, @floatFromInt(keyword_count)), ii);
            bytes += level_lines + level_lines * (average_length * ii);
        }
        std.debug.print("keywords: {d}\n\nlines: {d}\nbytes: {d}\n", .{ keyword_count, lines, bytes });
    }

    const stdout = std.io.getStdOut();
    var buffered_writer = std.io.bufferedWriter(stdout.writer());
    const stdout_writer = buffered_writer.writer();
    _ = stdout_writer;
}
