# Sleep from scratch

Implements a program that sleeps for a number of seconds from scratch using only system calls NO libc or standard Zig library.

Zig is already smart and the standard library doesn't use libc, so it can be implemented normally just using std. But I wanted to see if I could implement it without even needing the standard library.

## Build

To build the program, run
```
zig build -Dscratch=true
```

## inspiration

https://youtu.be/IbibjkI1kIs
https://github.com/valignatev/sleep-from-scratch/tree/master
