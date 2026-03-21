#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SRC_DIR="$SCRIPT_DIR/src"
EXAMPLES_DIR="$SCRIPT_DIR/examples"
TEJXC_BIN="${TEJXC:-tejxc}"

if ! command -v "$TEJXC_BIN" >/dev/null 2>&1; then
    echo "error: compiler '$TEJXC_BIN' was not found"
    echo "hint: put 'tejxc' on PATH or run with TEJXC=/path/to/tejxc"
    exit 1
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$SCRIPT_DIR/data"

build_target() {
    local label="$1"
    local source="$2"
    local output="$3"
    local source_dir
    local source_base
    local legacy_bin
    local legacy_ll

    source_dir=$(dirname "$source")
    source_base=$(basename "$source" .tx)
    legacy_bin="$source_dir/$source_base"
    legacy_ll="$source_dir/$source_base.ll"

    echo "Building $label -> $output"
    "$TEJXC_BIN" -o "$output" "$source"

    if [[ "$legacy_bin" != "$output" && -e "$legacy_bin" ]]; then
        echo "Removing legacy artifact -> $legacy_bin"
        rm -f "$legacy_bin"
    fi

    if [[ "$legacy_ll" != "$output.ll" && -e "$legacy_ll" ]]; then
        echo "Removing legacy artifact -> $legacy_ll"
        rm -f "$legacy_ll"
    fi
}

build_target "server" "$SRC_DIR/main.tx" "$BUILD_DIR/server"
build_target "example" "$EXAMPLES_DIR/probes/verify_net.tx" "$BUILD_DIR/verify_net"
build_target "example" "$EXAMPLES_DIR/clients/internal_client.tx" "$BUILD_DIR/internal_client"
build_target "example" "$EXAMPLES_DIR/probes/https_probe.tx" "$BUILD_DIR/https_probe"
build_target "example" "$EXAMPLES_DIR/probes/mongo_probe.tx" "$BUILD_DIR/mongo_probe"
build_target "example" "$EXAMPLES_DIR/probes/json_probe.tx" "$BUILD_DIR/json_probe"

echo "Build complete"
