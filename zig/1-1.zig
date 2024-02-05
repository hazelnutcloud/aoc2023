const std = @import("std");

fn getInput(allocator: std.mem.Allocator) !std.http.Client.FetchResult {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var headers = std.http.Headers.init(allocator);
    defer headers.deinit();
    try headers.append(
        "Cookie",
        "session=53616c7465645f5ff3c915ad896ad83ea1b1b8ca28087b5a996758231c6c2ffd056875ed676e23a4917eaedb57d5f27c14f1842954d9185df4e2bd11af28f552;",
    );

    return try client.fetch(allocator, .{
        .location = .{ .url = "https://adventofcode.com/2023/day/1/input" },
        .headers = headers,
    });
}

const Digit = struct {
    idx: usize,
    c: u8,
};

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_impl.allocator();
    defer if (gpa_impl.deinit() == .leak) {
        std.debug.print("Memory leak detected\n", .{});
    };

    var res = try getInput(allocator);
    defer res.deinit();

    if (res.status != .ok) {
        std.debug.print("Error {?s}", .{
            res.status.phrase(),
        });
        return;
    }

    if (res.body == null) {
        std.debug.print("Unexpected empty body", .{});
    }

    const input = res.body.?;

    var lines = std.mem.splitScalar(u8, input, '\n');

    var sum: u32 = 0;

    while (lines.next()) |line| {
        const first_digit: ?Digit = for (line, 0..) |c, idx| {
            if (c >= '0' and c <= '9') {
                break Digit{ .idx = idx, .c = c };
            }
        } else null;

        if (first_digit == null) {
            std.debug.print("No digit found in line: {s}\n", .{line});
            continue;
        }

        const first_idx = first_digit.?.idx;
        var len = line.len - 1;

        const second_digit: ?Digit = if (first_idx == len) first_digit else while (len >= first_idx) : (len -= 1) {
            const c = line[len];
            if (c >= '0' and c <= '9') {
                break Digit{ .idx = len, .c = c };
            }
        } else null;

        if (second_digit == null) {
            std.debug.print("No second digit found in line: {s}\n", .{line});
            continue;
        }

        const second_idx = second_digit.?.idx;

        const first = line[first_idx];
        const second = line[second_idx];

        const number_str = [_]u8{ first, second };
        const number = try std.fmt.parseInt(u32, &number_str, 10);

        std.debug.print("Line: {s} ", .{line});
        std.debug.print("Number: {d}\n", .{number});

        sum += number;
    }

    std.debug.print("Sum: {d}\n", .{sum});
}
