#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/arm32-jit-env.sh"

RELEASE_ROOT="$(arm32_jit_release_root)"
BEAM_BIN="$(arm32_jit_find_beam beam.debug.smp "$RELEASE_ROOT")"
BINDIR="$(dirname -- "$BEAM_BIN")"
HOME_DIR="$(arm32_jit_home_dir)"

export BINDIR
export EMU=beam.debug
export ROOTDIR="$RELEASE_ROOT"

exec qemu-arm -L /usr/arm-linux-gnueabihf "$BEAM_BIN" -v -A 0 -S 1:1 -SDcpu 1:1 -SDio 1 -JDdump true -JMsingle true -- \
    -root "$RELEASE_ROOT" \
    -bindir "$BINDIR" \
    -progname erl \
    -home "$HOME_DIR"
