# Copilot instructions

## Build, test, and lint commands

- Initialize the OTP fork before doing anything else: `git submodule update --init`
- Most scripted workflows assume the Docker-based Ubuntu 22.04 environment:
  - Build it with `./docker-build.sh`
  - Enter it with `./docker-shell.sh`
- Full ARM32 JIT builds from the repository root:
  - Release: `./jit-arm-release-full-build.sh`
  - Debug: `./jit-arm-debug-full-build.sh`
- Faster rebuilds when you changed source code but not build setup:
  - Release: `./rebuild-release.sh`
  - Debug: `./rebuild-debug.sh`
- Start the installed ARM32 release with `./run_release_erl.sh`
- Static checks in the OTP tree: `cd otp && ./otp_build check`
- Native OTP test targets in the submodule:
  - Full suite: `cd otp && make test`
  - One app: `cd otp && make stdlib_test`
  - One suite: `cd otp && make stdlib_test ARGS="-suite lists_SUITE"`
  - One case: `cd otp && make stdlib_test ARGS="-suite lists_SUITE -case member"`
- ARM32 JIT Common Test runner against the released tree:
  - App default: `./run_otp_lib_ct_jit.sh --app kernel`
  - One suite: `./run_otp_lib_ct_jit.sh --app kernel --suite logger_SUITE`
  - One case: `./run_otp_lib_ct_jit.sh --app stdlib --suite beam_lib_SUITE --case chunkify`

## High-level architecture

- This repository is a thin orchestration layer around the `otp/` git submodule. The actual Erlang/OTP source tree and ARM32 JIT implementation live there; the root-level shell scripts exist to build, test, and debug that fork.
- `Dockerfile`, `compose.yaml`, `docker-build.sh`, and `docker-shell.sh` define the expected development environment: Ubuntu 22.04 with cross-compilers, `qemu-user`, `gdb-multiarch`, Autoconf 2.72, and a host Erlang/OTP 27.0 installation for the OTP build tools.
- The full-build scripts run the OTP build pipeline in `otp/`: refresh generated configure scripts, configure with one of the custom ARM cross-compilation configs in `otp/xcomp/`, build OTP, create `otp/RELEASE`, and install a cross release there. The rebuild scripts skip the configure/bootstrap steps and reuse existing artifacts.
- Runtime and test workflows are built around that installed release, not around in-tree execution. `run_release_erl.sh` starts an interactive ARM32 release under `qemu-arm`, `run_otp_lib_ct_jit.sh` runs released Common Test suites from `otp/RELEASE`, and `run_debug.sh` / `run_clean.sh` / `gdb-debug.sh` / `gdb-release.sh` cover the ARM emulator/debugger flow.
- JIT implementation work is centered in `otp/erts/emulator/beam/jit/`. `beam_jit_main.cpp` owns global JIT runtime setup such as allocator selection and exported entry points, while `beam_jit_common.cpp` owns asmjit-backed code emission helpers and logging. ARM32-specific source paths are referenced under `otp/erts/emulator/beam/jit/arm/32`, and generated build outputs land under target-specific directories such as `otp/erts/emulator/armv7hl-unknown-linux-gnueabi/...`.

## Key conventions

- Run the root helper scripts from the repository root. The Docker helpers mount the repo at `/workspace/arm32-jit`, and the runtime/debug helpers now discover `otp/RELEASE/erts-*/bin` dynamically instead of assuming a fixed path.
- Treat `otp/RELEASE` as the canonical runtime artifact for this project. Test and debug scripts target that installed release rather than ad hoc binaries elsewhere in the build tree.
- Use a full build script after changing cross-compilation or configure-related inputs. Those scripts always run `./otp_build update_configure --no-commit` before `./otp_build configure`; the faster `rebuild-*.sh` scripts deliberately skip that setup.
- Keep debug and release behavior distinct. The debug cross-config adds `-DDEBUG -DJIT_HARD_DEBUG -O0 -DSMALL_MEMORY` and builds with `TYPE=debug`; the release config uses optimized flags and the non-debug make targets.
- Prefer `./run_otp_lib_ct_jit.sh` when you need to exercise the ARM32 JIT build under QEMU. It is the repo-specific test harness, supports `--suite` and `--case`, and propagates emulator runtime flags through `ERL_AFLAGS`.
- JIT debugging and inspection flows intentionally enable `+JDdump true`, and the debug launch scripts also enable `+JMsingle true`. Expect generated `.asm` dumps in the working directory when reproducing JIT issues.
- Do not hand-edit generated outputs in the OTP tree. Refresh configure scripts with `./otp_build update_configure --no-commit`, and regenerate preloaded-module content with `./otp_build update_preloaded --no-commit`.
- Keep `.docker-home/` untracked. `docker-shell.sh` uses it as the container HOME so Erlang/QEMU tooling has a writable per-repo home directory without relying on `/home/vagrant`.
