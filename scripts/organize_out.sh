#!/bin/bash

set -euo pipefail

OUT_DIR=${1:-out}

if [ ! -d "$OUT_DIR" ]; then
  echo "Output directory '$OUT_DIR' does not exist." >&2
  exit 1
fi

move_group() {
  local subdir=$1
  shift
  mkdir -p "$OUT_DIR/$subdir"
  shopt -s nullglob
  for pattern in "$@"; do
    for file in "$OUT_DIR"/$pattern; do
      [ -f "$file" ] || continue
      mv "$file" "$OUT_DIR/$subdir/"
    done
  done
  shopt -u nullglob
}

organize_natives() {
  shopt -s nullglob
  for file in "$OUT_DIR"/jcef-natives-*; do
    [ -f "$file" ] || continue
    local base rest platform dest
    base=$(basename "$file")
    rest=${base#jcef-natives-}
    platform=${rest%%-jcef-*}
    dest="$OUT_DIR/natives/$platform"
    mkdir -p "$dest"
    mv "$file" "$dest/"
  done
  shopt -u nullglob
}

move_group "jogl-all" "jogl-all-*"
move_group "gluegen-rt" "gluegen-rt-*"
move_group "jcef-api" "jcef-api-*"
move_group "jcefmaven" "jcefmaven-*"
organize_natives

echo "Artifacts reorganized under $OUT_DIR/"
