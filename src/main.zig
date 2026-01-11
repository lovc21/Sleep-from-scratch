const SYS_write: usize = 1;
const SYS_nanosleep: usize = 35;
const SYS_exit: usize = 60;

// struct for timespec rquired by the kernel
const Timespec = extern struct {
    tv_sec: isize,
    tv_nsec: isize,
};

// syscall for exit function that the assembly in _start can find and call and exit the program
pub export fn exit(code: u8) noreturn {
    asm volatile ("syscall"
        :
        : [number] "{rax}" (SYS_exit),
          [arg1] "{rdi}" (code),
        : .{ .rcx = true, .r11 = true });
    unreachable;
}

// syscalls for sleeping
fn syscall2(number: usize, arg1: usize, arg2: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
        : .{ .rcx = true, .r11 = true, .memory = true });
}

// syscalls for writing
fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : .{ .rcx = true, .r11 = true, .memory = true });
}

// convert a pointer to a string to a length
fn get_len(ptr: [*]const u8) usize {
    var i: usize = 0;
    while (ptr[i] != 0) : (i += 1) {}
    return i;
}

// parse an integer from a string
fn parse_int(raw_int: []const u8) !u64 {
    var result: u64 = 0;

    for (raw_int) |c| {
        if (c < '0' or c > '9') break;
        result = result * 10 + (c - '0');
    }

    return result;
}

// write a number to stdout
fn print_u64(n: u64) !void {
    var buf: [32]u8 = undefined;
    var i: usize = buf.len;
    var val = n;

    if (val == 0) {
        print("0") catch {
            return;
        };
        return;
    }

    while (val > 0) {
        i -= 1;
        buf[i] = @as(u8, @intCast(val % 10)) + '0';
        val /= 10;
    }
    print(buf[i..]) catch {
        return;
    };
}

// write a string to stdout
fn print(string: []const u8) !void {
    _ = syscall3(SYS_write, 1, @intFromPtr(string.ptr), string.len);
}

// sleep for a number of seconds
fn sleep(seconds: u64) void {
    const ts = Timespec{
        .tv_sec = @intCast(seconds),
        .tv_nsec = 0,
    };

    _ = syscall2(SYS_nanosleep, @intFromPtr(&ts), 0);
}

// export main so we can call it from assembly
pub export fn main(argc: c_int, argv: [*][*]u8) u8 {
    const args = argv[0..@intCast(argc)];

    if (args.len != 2) {
        print("Usage: sleep NUMBER\nPause for NUMBER seconds\n") catch {
            return 2;
        };
        return 1;
    }

    const raw_ptr = args[1];
    const len = get_len(raw_ptr);
    const arg_slice = raw_ptr[0..len];

    const seconds = parse_int(arg_slice) catch {
        print("Error: Invalid number\n") catch {
            return 2;
        };
        return 1;
    };

    print("Sleeping for ") catch {
        return 2;
    };
    print_u64(seconds) catch {
        return 2;
    };
    print(" seconds...\n") catch {
        return 2;
    };

    sleep(seconds);

    return 0;
}

// start of the program
// define a neked start so we can find main
// https://ziglang.org/documentation/0.15.2/#toc-Entry-Point
// https://ziglang.org/documentation/0.15.2/#Functions -> how to make a neked function
// https://github.com/valignatev/sleep-from-scratch/blob/master/sleep.c#L118
pub export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\ xor %%ebp, %%ebp
        \\ movq (%%rsp), %%rdi
        \\ leaq 8(%%rsp), %%rsi
        \\ andq $-16, %%rsp
        \\ callq %[main:P]
        \\ movq %%rax, %%rdi
        \\ callq %[exit:P]
        :
        : [main] "X" (&main),
          [exit] "X" (&exit),
    );
}
