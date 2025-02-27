const std = @import("std");
const lib = @import("totp_cli_lib");

const time = std.time;
const math = std.math;
const json = std.json;
const epoch = time.epoch;
const Allocator = std.mem.Allocator;

const totp = @import("zig-totp");

const version = "1.0.0";

pub fn main() !void {
    std.debug.print("Totp Cli started, version {s}. \n\n", .{version});

    const alloc = std.heap.page_allocator;

    const secret = getSecret(alloc) catch {
        std.debug.print("conf.json not exists.\n", .{});

        return ;
    };
    var passcode = try generateCode(alloc, secret);

    if (secret.len == 0) {
        std.debug.print("conf.json secret not exists.\n", .{});

        return ;
    }

    const period = 30;
    var t = try time.Timer.start();
    while (true) {
        if (t.read() > time.ns_per_s) {
            const sec = math.comptimeMod(getSecond(), period);
            if (sec == 0) {
                t.reset();

                passcode = try generateCode(alloc, secret);
        
                std.debug.print("passcode: {s}, next generate: 0s \r", .{passcode});
            } else {
                std.debug.print("passcode: {s}, next generate: {d}s \r", .{passcode, period - sec});
            }
        }

    }

}

fn getSecret(alloc: Allocator) ![]const u8 {
    const file = "conf.json";

    var open_file = std.fs.cwd().openFile(file, .{ .mode = .read_only }) catch {
       return "";
    };
    defer open_file.close();

    const file_length = (try open_file.metadata()).size();
    const content = try open_file.readToEndAlloc(alloc, file_length);

    if (content.len == 0) {
        return content;
    }

    const parsed = try json.parseFromSlice(json.Value, alloc, content, .{});

    var secret: []const u8 = "";
    if (parsed.value.object.get("secret")) |val| {
        if (val == .string) {
            secret = val.string;
        }
    }

    return secret;
}

fn generateCode(alloc: Allocator, secret: []const u8) ![]const u8 {
    const n = totp.time.now().utc();
    const passcode = try totp.generateCode(alloc, secret, n);

    return passcode;
}

fn getSecond() u6 {
    const es = epoch.EpochSeconds{
        .secs = @as(u64, @intCast(time.timestamp())),
    };

    const sec = es.getDaySeconds().getSecondsIntoMinute();
    return sec;
}

