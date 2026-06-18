# Development Setup for the ARM32 JIT

The ARM32 JIT is working! Yeeee!

Try it yourself by following this guide!

#### **Things to keep in mind**

- Not ready for production
- Good for use in tests and to do experimentations or benchmarks
- Based on top of OTP 27.0
- Only partially tested with OTP Suites
- Arm32 JIT emitters are not fully optimized

## Usage of the Docker environment

To build and run the ARM32 JIT on a 64-bit system, use the Docker-based Ubuntu
22.04 environment in this repository. The image installs the cross-compilers,
`qemu-user`, `gdb-multiarch`, Autoconf 2.72, and a host Erlang/OTP 27.0 build
needed by the OTP build tooling.

### Requirements

- Docker Desktop or a recent Docker Engine with the Compose plugin

### Build the development image

```shell
./docker-build.sh
```

### Start a shell in the container

```shell
./docker-shell.sh
```

The repository is bind-mounted into `/workspace/arm32-jit`, so files created by
the build remain visible on the host immediately. The helper script also creates
`.docker-home/` for the container user's home directory and publishes TCP port
`1234` for QEMU's GDB stub.

### Initialize the OTP submodule

Do this once on the host before starting the container shell.

```shell
git submodule update --init
```

## Quick release build

Cross-build and install a release:

```shell
./docker-shell.sh ./jit-arm-release-full-build.sh
```

The release is installed under `otp/RELEASE`. To start the installed ARM32
release under QEMU:

```shell
./docker-shell.sh ./run_release_erl.sh
Erlang/OTP 27 [erts-15.0] [source-4ecd178167] [32-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Eshell V15.0 (press Ctrl+G to abort, type help(). for help)
1>
```
You are free to experiment with this Erlang release.

### Run OTP test suites with the ARM32 JIT release

If you want to run test suites, we created a custom script to run OTP suites.

```shell
./docker-shell.sh ./run_otp_lib_ct_jit.sh
```

This script lets you choose an app, suite, and test case. Keep in mind that a
few tests may fail simply because they run through an emulation layer. Expect
timeout errors.

## Cross-compile OTP and Debug with GDB

There are multiple scripts that can be used to compile OTP and run GDB from
inside the container:
```shell
# Build with debug symbols and JIT checks
./jit-arm-debug-full-build.sh 
# Clean and optimized build
./jit-arm-release-full-build.sh 
```
These scripts follow the guidelines to cross-compile to the custom ARM Linux
setup we added under `xcomp`. Use them to refresh the configure scripts and
build the codebase with ARM32 JIT code.

If you modify code but do not change the build setup, you can run a faster
recompilation script that skips the early steps and reuses compiled artifacts.

```shell
## depending on which type of build you desire
./rebuild-debug.sh
./rebuild-release.sh
```
In early development, or when debugging early crashes, it is useful to work
with a debug build and the scripts below. They use `qemu-user` to run
`beam.debug.smp` with a GDB server. This way, QEMU emulates the processor and
waits for GDB for step-by-step debugging.

```shell 
./docker-shell.sh ./run_debug.sh   # run debug build and wait for GDB to connect
./docker-shell.sh ./run_clean.sh   # run debug build without a GDB listener
./docker-shell.sh ./gdb-debug.sh   # attach from inside the container
./docker-shell.sh ./debug.sh       # shortcut for ./run_debug.sh and ./gdb-debug.sh
```

You can modify these scripts to target `beam.smp` instead of
`beam.debug.smp`, so they work for the release build. For convenience, there is
another script for GDB.

```shell
./docker-shell.sh ./gdb-release.sh
```

If you prefer to run GDB on the host, keep `./docker-shell.sh ./run_debug.sh`
running and then connect to `localhost:1234` with `gdb-multiarch`.

## Inspecting JITted code

We run OTP with `JDdump true`; this dumps all JITted assembly into `.asm` files.

For example, you can find JITted assembly for global functions
in the current working directory.

The global assembler output is written to `beam_asm_global.asm` in the working
directory.

```shell
cat beam_asm_global.asm
global::apply_fun_shared:
    eor r2, r2, r2
    ldr r3, [r4, 64]
    ldr r1, [r4, 68]
    mov r0, r1
L100:
    cmp r0, 59
    b.eq L99
    tst r0, 1
    b.ne L101
    ldr r12, [r0, -1]
    ldr r0, [r0, 3]
    str r12, [r4, r2 lsl 2]
    movw r12, 1023
    add r2, r2, 1
    cmp r2, r12
    b.lo L100
    movw r0, 15440
    b L102
L101:
    movw r0, 3152
L102:
    str r3, [r4, 64]
    str r1, [r4, 68]
    str r0, [r8, 56]
    movw r3, 53184
    movt r3, 16459
    b global::raise_exception
L99:
    lsl r2, r2, 8
    add r2, r2, 20
    bx lr
```
Because the repository is bind-mounted into the container, generated `.asm`
files are already available on the host without any copy step.
## Preloaded module content

Preloaded modules are updated by running
```shell
./otp_build update_preloaded --no-commit
```
During the build, the BEAM binaries of preloaded modules end up in a generated
C file that is included in the build. To include `hello` as an extra module,
you need to:

1. Place `hello.erl` in `otp/erts/preloaded/src`.
2. Add `hello` to `PRE_LOADED_ERL_MODULES` in `erts/preloaded/src/Makefile`.
3. Put `hello.beam` at the top of `erts/emulator/Makefile.in` (to load it first).
4. Add the `hello` atom to `erts/emulator/beam/atom.names`.
5. Make sure to update and rerun `configure`.
6. (Optional) Swap `init` with `hello` in `erl_init.c` to make BEAM boot into
   `hello` instead of the normal Erlang initialization.
7. Build again.

You can check the content of the `pre_loaded` vector by reading this file:

    erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/preload.c 

By placing `hello` first in the list in `Makefile.in`, we ensure it is loaded
first. If we comment out everything else, we get the smallest module possible.
```c
erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/preload.c 
/*
 * Do *not* edit this file. It was automatically generated by
 * `make_preload'.
 */
const unsigned preloaded_size_hello = 232;
const unsigned char preloaded_hello[] = {
0x46,0x4f,0x52,0x31,0x00,0x00,0x00,0xe0, /* FOR1.... */
  0x42,0x45,0x41,0x4d,0x41,0x74,0x55,0x38, /* BEAMAtU8 */
  0x00,0x00,0x00,0x2d,0x00,0x00,0x00,0x04, /* ...-.... */
  0x05,0x68,0x65,0x6c,0x6c,0x6f,0x0b,0x6d, /* .hello.m */
  0x6f,0x64,0x75,0x6c,0x65,0x5f,0x69,0x6e, /* odule_in */
  0x66,0x6f,0x06,0x65,0x72,0x6c,0x61,0x6e, /* fo.erlan */
  0x67,0x0f,0x67,0x65,0x74,0x5f,0x6d,0x6f, /* g.get_mo */
  0x64,0x75,0x6c,0x65,0x5f,0x69,0x6e,0x66, /* dule_inf */
  0x6f,0x00,0x00,0x00,0x43,0x6f,0x64,0x65, /* o...Code */
  0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x10, /* ...8.... */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xab, /* ........ */
  0x00,0x00,0x00,0x05,0x00,0x00,0x00,0x02, /* ........ */
  0x01,0x10,0x99,0x00,0x02,0x12,0x22,0x00, /* ......". */
  0x01,0x20,0x40,0x12,0x03,0x4e,0x10,0x00, /* . @..N.. */
  0x01,0x30,0x99,0x00,0x02,0x12,0x22,0x10, /* .0....". */
  0x01,0x40,0x40,0x03,0x13,0x40,0x12,0x03, /* .@@..@.. */
  0x4e,0x20,0x10,0x03,0x45,0x78,0x70,0x54, /* N ..ExpT */
  0x00,0x00,0x00,0x1c,0x00,0x00,0x00,0x02, /* ........ */
  0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x01, /* ........ */
  0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x02, /* ........ */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02, /* ........ */
  0x49,0x6d,0x70,0x54,0x00,0x00,0x00,0x1c, /* ImpT.... */
  0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x03, /* ........ */
  0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x01, /* ........ */
  0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x04, /* ........ */
  0x00,0x00,0x00,0x02,0x53,0x74,0x72,0x54, /* ....StrT */
  0x00,0x00,0x00,0x00,0x54,0x79,0x70,0x65, /* ....Type */
  0x00,0x00,0x00,0x0a,0x00,0x00,0x00,0x03, /* ........ */
  0x00,0x00,0x00,0x01,0x0f,0xff,0x00,0x00,                       
                  /* ........ */
};
...
const struct {
   char* name;
   int size;
   const unsigned char* code;
} pre_loaded[] = {
  {"hello", 232, preloaded_hello},
  {"erts_code_purger", 5432, preloaded_erts_code_purger},
  {"erl_init", 1148, preloaded_erl_init},
  {"init", 25752, preloaded_init},
  ...

```
