const std = @import("std");
const lib = @import("totp_cli_lib");

const time = std.time;
const json = std.json;
const epoch = time.epoch;
const Allocator = std.mem.Allocator;

const totp = @import("zig-totp");
const otps = totp.otps;

const version = "1.1.0";

pub fn main() !void {
    std.debug.print("Totp Cli started. \n", .{});
    std.debug.print("version {s}. \n\n", .{version});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const file = "conf.json";
    const confs = getConf(alloc, file) catch {
        std.debug.print("conf.json not exists.\n", .{});
        return;
    };

    if (confs.len == 0) {
        std.debug.print("totp conf is empty.\n", .{});
        return;
    }

    const conf = confs[0];
    const period = conf.period;

    var passcode: []const u8 = "";

    var t = try time.Timer.start();
    while (true) {
        if (passcode.len == 0) {
            passcode = try generateCode(alloc, conf);
        }

        if (t.read() > time.ns_per_s) {
            const sec = @mod(getSecond(), period);
            if (sec == 0) {
                passcode = try generateCode(alloc, conf);

                std.debug.print("[{s}] passcode: {s}, next generate: 0s \r", .{ conf.name, passcode });
            } else {
                std.debug.print("[{s}] passcode: {s}, next generate: {d}s \r", .{ conf.name, passcode, period - sec });
            }

            t.reset();
        }
    }
}

const Conf = struct {
    name: []const u8,
    secret: []const u8,
    period: u32 = 30,
    digits: otps.Digits = .Six,
    algorithm: otps.Algorithm = .SHA1,
    encoder: otps.Encoder = .Default,
};

fn getConf(alloc: Allocator, file: []const u8) ![]Conf {
    var list = std.ArrayList(Conf).init(alloc);
    defer list.deinit();

    var open_file = try std.fs.cwd().openFile(file, .{ .mode = .read_only });
    defer open_file.close();

    const file_length = (try open_file.metadata()).size();
    const content = try open_file.readToEndAlloc(alloc, file_length);

    if (content.len == 0) {
        return try list.toOwnedSlice();
    }

    const parsed = try json.parseFromSlice(json.Value, alloc, content, .{});
    var root = parsed.value;

    if (root.object.get("totp")) |totps| {
        for (totps.array.items) |item| {
            var name: []const u8 = "";
            var secret: []const u8 = "";
            var period: u32 = 30;
            var digits: otps.Digits = .Six;
            var algorithm: otps.Algorithm = .SHA1;
            var encoder: otps.Encoder = .Default;

            if (item.object.get("name")) |val| {
                if (val == .string) {
                    name = val.string;
                }
            }
            if (item.object.get("secret")) |val| {
                if (val == .string) {
                    secret = val.string;
                }
            }
            if (item.object.get("period")) |val| {
                if (val == .integer) {
                    period = @as(u32, @intCast(val.integer));
                }
            }
            if (item.object.get("digits")) |val| {
                if (val == .integer) {
                    digits = otps.Digits.init(@as(u32, @intCast(val.integer)));
                }
            }
            if (item.object.get("algorithm")) |val| {
                if (val == .string) {
                    if (std.mem.eql(u8, val.string, "SHA1")) {
                        algorithm = .SHA1;
                    } else if (std.mem.eql(u8, val.string, "SHA256")) {
                        algorithm = .SHA256;
                    } else if (std.mem.eql(u8, val.string, "SHA512")) {
                        algorithm = .SHA512;
                    } else {
                        algorithm = .MD5;
                    }
                }
            }
            if (item.object.get("encoder")) |val| {
                if (val == .string) {
                    if (std.mem.eql(u8, val.string, "Steam")) {
                        encoder = .Steam;
                    } else {
                        encoder = .Default;
                    }
                }
            }

            try list.append(.{
                .name = name,
                .secret = secret,
                .period = period,
                .digits = digits,
                .algorithm = algorithm,
                .encoder = encoder,
            });
        }
    }

    return try list.toOwnedSlice();
}

fn generateCode(alloc: Allocator, conf: Conf) ![]const u8 {
    const t = totp.time.now().utc();

    const passcode = try totp.generateCodeCustom(alloc, conf.secret, t, .{
        .period = conf.period,
        .skew = 1,
        .digits = conf.digits,
        .algorithm = conf.algorithm,
        .encoder = conf.encoder,
    });

    return passcode;
}

fn getSecond() u6 {
    const es = epoch.EpochSeconds{
        .secs = @as(u64, @intCast(time.timestamp())),
    };

    const sec = es.getDaySeconds().getSecondsIntoMinute();
    return sec;
}
