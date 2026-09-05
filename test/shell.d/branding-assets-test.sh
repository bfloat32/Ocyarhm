#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

expected=$(
  cat <<'WORDMARK'
  ██████      ██████    ████████      ██████                  ██████      ████████
██      ██  ██      ██  ██      ██  ██      ██              ██      ██  ██
██      ██  ██      ██  ██                      ██      ██  ██
██      ██  ██      ██  ████████    ████████                ██      ██    ██████
  ████████  ██      ██  ██  ██      ██                      ██      ██          ██
        ██  ██      ██  ██    ██    ██      ██      ████    ██      ██          ██
        ██    ██████    ██      ██    ██████        ████      ██████    ████████
WORDMARK
)

[[ $(cat "$ROOT/logo.txt") == "$expected" ]] || fail "logo.txt is the qore.os wordmark"
[[ $(cat "$ROOT/icon.txt") == "$expected" ]] || fail "icon.txt is the qore.os wordmark"
cmp -s "$ROOT/logo.txt" "$ROOT/icon.txt" || fail "terminal and About defaults share one wordmark"
(( $(wc -l <"$ROOT/logo.txt") == 7 )) || fail "logo.txt has seven matrix rows"
(( $(awk 'length > max { max = length } END { print max + 0 }' "$ROOT/logo.txt") == 82 )) || fail "logo.txt is 82 columns wide"
pass "text branding uses the exact qore.os matrix"

grep -Fq '<title>qore.os</title>' "$ROOT/logo.svg" || fail "logo.svg labels the qore.os wordmark"
grep -Fq 'shape-rendering="crispEdges"' "$ROOT/logo.svg" || fail "logo.svg keeps pixel geometry crisp"
pass "SVG branding carries the qore.os identity"

node - "$ROOT" <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.argv[2];
const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function pngSize(relative, width, height) {
  const bytes = fs.readFileSync(path.join(root, relative));
  if (!bytes.subarray(0, 8).equals(signature)) throw new Error(`${relative} is not a PNG`);
  if (bytes.readUInt32BE(8) !== 13 || bytes.subarray(12, 16).toString() !== "IHDR") throw new Error(`${relative} has no IHDR`);
  if (bytes.readUInt32BE(16) !== width || bytes.readUInt32BE(20) !== height) throw new Error(`${relative} has the wrong dimensions`);
  if (bytes[24] !== 8 || bytes[25] !== 6) throw new Error(`${relative} is not 8-bit RGBA`);
}

pngSize("icon.png", 300, 300);
pngSize("default/plymouth/logo.png", 800, 188);
pngSize("default/sddm/omarchy/logo.png", 800, 188);
if (!fs.readFileSync(path.join(root, "default/plymouth/logo.png")).equals(fs.readFileSync(path.join(root, "default/sddm/omarchy/logo.png")))) throw new Error("Plymouth and SDDM logos differ");
NODE
pass "PNG branding assets have valid signatures, dimensions, and parity"
