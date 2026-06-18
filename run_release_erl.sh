#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/arm32-jit-env.sh"

RELEASE_ROOT="$(arm32_jit_release_root)"
BEAM_NAME="${BEAM_NAME:-beam.smp}"
BEAM_BIN="${BEAM_BIN:-$(arm32_jit_find_beam "$BEAM_NAME" "$RELEASE_ROOT")}"
BINDIR="$(dirname -- "$BEAM_BIN")"
HOME_DIR="$(arm32_jit_home_dir)"

exec qemu-arm -L /usr/arm-linux-gnueabihf "$BEAM_BIN" -- \
    -root "$RELEASE_ROOT" \
    -bindir "$BINDIR" \
    -boot start \
    -progname erl \
    -home "$HOME_DIR" \
    "$@"
