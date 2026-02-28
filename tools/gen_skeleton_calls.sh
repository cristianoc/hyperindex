#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/src/skeleton_calls"
BLACKLIST="$ROOT/src/skeleton_calls/.blacklist_pairs"
mkdir -p "$OUT_DIR"
: > "$OUT_DIR/.generated_files"
rm -f "$OUT_DIR"/Skeleton_*.res

# Build set of available top-level ReScript modules in envio
mapfile -t ENVIO_MODULES < <(
  cd "$ROOT" && rg --files codegenerator/cli/npm/envio/src -g '*.res' -g '*.resi' \
    | sed 's#^.*/##' \
    | sed -E 's/\.(res|resi)$//' \
    | sort -u
)

is_envio_module() {
  local m="$1"
  for x in "${ENVIO_MODULES[@]}"; do
    if [[ "$x" == "$m" ]]; then
      return 0
    fi
  done
  return 1
}

is_blacklisted() {
  local k="$1"
  [[ -f "$BLACKLIST" ]] && grep -Fqx "$k" "$BLACKLIST"
}

sanitize_name() {
  echo "$1" | sed -E "s/[^A-Za-z0-9_]/_/g"
}

# Removed sources/tests/templates that likely contained runtime usage
mapfile -t FILES < <(
  cd "$ROOT" && git ls-files \
    | rg '^scenarios/.*/(src|test)/.*\.(res|resi|ts|js)$|^codegenerator/cli/templates/static/.*/src/.*\.(res|ts|js)$' -S
)

for rel in "${FILES[@]}"; do
  content="$(cd "$ROOT" && git show "HEAD:$rel" 2>/dev/null || true)"
  [[ -z "$content" ]] && continue

  mapfile -t pairs < <(
    printf "%s\n" "$content" \
      | rg -o "\\b([A-Z][A-Za-z0-9_]*)\\.([a-z][A-Za-z0-9_']*)" \
      | sort -u
  )

  out_pairs=()
  for p in "${pairs[@]}"; do
    mod="${p%%.*}"
    fn="${p#*.}"
    key="$mod.$fn"
    if is_envio_module "$mod" && ! is_blacklisted "$key"; then
      out_pairs+=("$key")
    fi
  done

  [[ ${#out_pairs[@]} -eq 0 ]] && continue

  stem="$(sanitize_name "$rel")"
  out="$OUT_DIR/Skeleton_${stem}.res"

  {
    echo "/* Auto-generated from $rel. */"
    echo "let touch_all = () => {"
    for key in "${out_pairs[@]}"; do
      mod="${key%%.*}"
      fn="${key#*.}"
      sfn="$(sanitize_name "$fn")"
      echo "    // $key"
      echo "    let _${mod}_${sfn} = (Obj.magic(${mod}.${fn}): unit => unit)"
      echo "    ignore(_${mod}_${sfn}())"
    done
    echo "}"
    echo "let _ = touch_all()"
  } > "$out"

  echo "$out" >> "$OUT_DIR/.generated_files"
done
