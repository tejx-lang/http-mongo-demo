#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SRC_DIR="$SCRIPT_DIR/src"
EXAMPLES_DIR="$SCRIPT_DIR/examples"
LOCAL_TEJX_ROOT="$SCRIPT_DIR/../tejx-lang"
LOCAL_TEJXC="$LOCAL_TEJX_ROOT/target/release/tejxc"
LOCAL_TEJX_STDLIB="$LOCAL_TEJX_ROOT/src/library"
LOCAL_TEJX_RUNTIME="$LOCAL_TEJX_ROOT/target/release/tejx_rt.a"
DEFAULT_TEJXC="$HOME/.tejx/bin/tejxc"
TEJXC_BIN="${TEJXC:-}"
TEJXC_STDLIB_PATH="${TEJXC_STDLIB_PATH:-}"
TEJXC_RUNTIME_PATH="${TEJXC_RUNTIME_PATH:-}"

if [[ -z "$TEJXC_BIN" ]]; then
    if [[ -x "$LOCAL_TEJXC" && -d "$LOCAL_TEJX_STDLIB" && -f "$LOCAL_TEJX_RUNTIME" ]]; then
        TEJXC_BIN="$LOCAL_TEJXC"
    elif command -v tejxc >/dev/null 2>&1; then
        TEJXC_BIN="tejxc"
    elif [[ -x "$DEFAULT_TEJXC" ]]; then
        TEJXC_BIN="$DEFAULT_TEJXC"
    else
        TEJXC_BIN="tejxc"
    fi
fi

if [[ ! -x "$TEJXC_BIN" ]] && ! command -v "$TEJXC_BIN" >/dev/null 2>&1; then
    echo "error: compiler '$TEJXC_BIN' was not found"
    echo "hint: build ../tejx-lang, put 'tejxc' on PATH, install it to '$DEFAULT_TEJXC', or run with TEJXC=/path/to/tejxc"
    exit 1
fi

if [[ -z "$TEJXC_STDLIB_PATH" && "$TEJXC_BIN" == "$LOCAL_TEJXC" && -d "$LOCAL_TEJX_STDLIB" ]]; then
    TEJXC_STDLIB_PATH="$LOCAL_TEJX_STDLIB"
fi

if [[ -z "$TEJXC_RUNTIME_PATH" && "$TEJXC_BIN" == "$LOCAL_TEJXC" && -f "$LOCAL_TEJX_RUNTIME" ]]; then
    TEJXC_RUNTIME_PATH="$LOCAL_TEJX_RUNTIME"
fi

mkdir -p "$BUILD_DIR"

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
    local compile_cmd=("$TEJXC_BIN")
    if [[ -n "$TEJXC_STDLIB_PATH" ]]; then
        compile_cmd+=(--stdlib-path "$TEJXC_STDLIB_PATH")
    fi
    if [[ -n "$TEJXC_RUNTIME_PATH" ]]; then
        compile_cmd+=(--runtime-path "$TEJXC_RUNTIME_PATH")
    fi
    compile_cmd+=(-o "$output" "$source")
    "${compile_cmd[@]}"

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

echo "Build complete"
