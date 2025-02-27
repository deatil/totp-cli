# build

~~~
zig build-exe . -target x86_64-native -mcpu sandybridge

zig build-exe -O ReleaseSmall -fstrip -fsingle-threaded -target x86_64-linux
zig build-exe -O ReleaseSmall -fstrip -fsingle-threaded -target x86_64-windows
zig build-exe -O ReleaseSmall -fstrip -fsingle-threaded -target x86_64-macos --name totp-cli
zig build-exe -O ReleaseSmall -fstrip -fsingle-threaded --name totp-cli
~~~

~~~
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSmall --summary all 
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --summary all 
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSmall --summary all 
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --summary all --prefix-exe-dir ./
~~~

~~~
	            Runtime  Safety	  Optimizations
Debug	        Yes	     No
ReleaseSafe	    Yes	     Yes,     Speed
ReleaseSmall	No	     Yes,     Size
ReleaseFast	    No	     Yes,     Speed
~~~

Some CPU architectures that you can cross-compile for:
~~~
    x86_64
    arm
    aarch64
    i386
    riscv64
    wasm32
~~~

Some operating systems you can cross-compile for:
~~~
    linux
    macos
    windows
    freebsd
    netbsd
    dragonfly
    UEFI
~~~