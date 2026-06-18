#!/usr/bin/env bash

ARM32_JIT_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

arm32_jit_repo_root() {
    printf '%s\n' "${ARM32_JIT_REPO_ROOT}"
}

arm32_jit_otp_root() {
    printf '%s\n' "${ARM32_JIT_OTP_ROOT:-${ARM32_JIT_REPO_ROOT}/otp}"
}

arm32_jit_release_root() {
    printf '%s\n' "${ARM32_JIT_RELEASE_ROOT:-$(arm32_jit_otp_root)/RELEASE}"
}

arm32_jit_home_dir() {
    printf '%s\n' "${ARM32_JIT_HOME:-${HOME:-${ARM32_JIT_REPO_ROOT}/.docker-home}}"
}

arm32_jit_find_erts_bindir() {
    local release_root="${1:-$(arm32_jit_release_root)}"
    local bindir

    bindir="$(find "$release_root" -maxdepth 2 -type d -path "$release_root/erts-*/bin" | LC_ALL=C sort | head -n 1)"
    [[ -n "$bindir" ]] || return 1

    printf '%s\n' "$bindir"
}

arm32_jit_find_beam() {
    local beam_name="${1:-beam.smp}"
    local release_root="${2:-$(arm32_jit_release_root)}"
    local bindir
    local beam_path

    bindir="$(arm32_jit_find_erts_bindir "$release_root")" || return 1
    beam_path="${bindir}/${beam_name}"
    [[ -x "$beam_path" ]] || return 1

    printf '%s\n' "$beam_path"
}

arm32_jit_find_jit_build_dir() {
    local otp_root="${1:-$(arm32_jit_otp_root)}"
    local build_dir

    build_dir="$(find "$otp_root/erts/emulator" -type d -path "*/opt/jit" | LC_ALL=C sort | head -n 1)"
    [[ -n "$build_dir" ]] || return 1

    printf '%s\n' "$build_dir"
}
