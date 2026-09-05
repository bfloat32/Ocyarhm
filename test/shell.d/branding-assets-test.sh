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

require_command node

node - "$ROOT" <<'NODE'
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const root = process.argv[2];
const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const WORDMARK = [
  "  ██████      ██████    ████████      ██████                  ██████      ████████",
  "██      ██  ██      ██  ██      ██  ██      ██              ██      ██  ██",
  "██      ██  ██      ██  ██                      ██      ██  ██",
  "██      ██  ██      ██  ████████    ████████                ██      ██    ██████",
  "  ████████  ██      ██  ██  ██      ██                      ██      ██          ██",
  "        ██  ██      ██  ██    ██    ██      ██      ████    ██      ██          ██",
  "        ██    ██████    ██      ██    ██████        ████      ██████    ████████",
];

const assets = {
  "icon.png": {
    width: 300, height: 300, background: [158, 206, 106, 255], foreground: [0, 0, 0, 255],
    cellWidth: 5, cellHeight: 20, originX: 47, originY: 80,
  },
  "default/plymouth/logo.png": {
    width: 800, height: 188, background: [0, 0, 0, 0], foreground: [168, 205, 118, 255],
    cellWidth: 18, cellHeight: 22, originX: 31, originY: 17,
  },
  "default/sddm/omarchy/logo.png": {
    width: 800, height: 188, background: [0, 0, 0, 0], foreground: [168, 205, 118, 255],
    cellWidth: 18, cellHeight: 22, originX: 31, originY: 17,
  },
};

function cells(cellWidth, cellHeight, originX, originY) {
  const result = [];
  for (let row = 0; row < WORDMARK.length; row++) {
    const text = WORDMARK[row].padEnd(82, " ");
    for (let column = 0; column < 41; column++) {
      if (text.slice(column * 2, column * 2 + 2) === "██") {
        result.push({
          x: originX + column * cellWidth,
          y: originY + row * cellHeight,
          width: cellWidth,
          height: cellHeight,
        });
      }
    }
  }
  return result;
}

function attribute(source, name) {
  const match = source.match(new RegExp(`\\b${name}="([^"]*)"`));
  if (!match) throw new Error(`missing SVG ${name} attribute`);
  return match[1];
}

const svg = fs.readFileSync(path.join(root, "logo.svg"), "utf8");
const svgRoot = svg.match(/^<svg\b[^>]*>/)?.[0];
if (!svgRoot) throw new Error("logo.svg has no SVG root");
if (attribute(svgRoot, "width") !== "1215" || attribute(svgRoot, "height") !== "285" || attribute(svgRoot, "viewBox") !== "0 0 1215 285") {
  throw new Error("logo.svg has the wrong canvas dimensions");
}
if (attribute(svgRoot, "shape-rendering") !== "crispEdges") throw new Error("logo.svg is not crisp");
if (!svg.includes("<title>qore.os</title>")) throw new Error("logo.svg has the wrong title");
if (/<text\b|font-family|@import|<use\b/.test(svg)) throw new Error("logo.svg uses text or an external font");

const actualRects = [...svg.matchAll(/<rect\b[^>]*\/>/g)].map((match) => {
  const source = match[0];
  return {
    x: Number(attribute(source, "x")), y: Number(attribute(source, "y")),
    width: Number(attribute(source, "width")), height: Number(attribute(source, "height")),
    fill: attribute(source, "fill"),
  };
});
const expectedRects = cells(25, 30, 95, 37).map((rect) => ({ ...rect, fill: "black" }));
const rectKey = (rect) => `${rect.x},${rect.y},${rect.width},${rect.height},${rect.fill}`;
const actualRectKeys = actualRects.map(rectKey).sort();
const expectedRectKeys = expectedRects.map(rectKey).sort();
if (JSON.stringify(actualRectKeys) !== JSON.stringify(expectedRectKeys)) {
  throw new Error(`SVG rectangles do not match the canonical matrix (expected ${expectedRects.length}, got ${actualRects.length})`);
}

function decodePng(relative, spec) {
  const bytes = fs.readFileSync(path.join(root, relative));
  if (!bytes.subarray(0, 8).equals(signature)) throw new Error(`${relative} is not a PNG`);
  let offset = 8;
  let header;
  const idat = [];
  while (offset < bytes.length) {
    if (offset + 12 > bytes.length) throw new Error(`${relative} has a truncated chunk`);
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString();
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) throw new Error(`${relative} has a truncated ${type} chunk`);
    const data = bytes.subarray(dataStart, dataEnd);
    if (type === "IHDR") header = data;
    if (type === "IDAT") idat.push(data);
    offset = dataEnd + 4;
    if (type === "IEND") break;
  }
  if (!header || idat.length === 0) throw new Error(`${relative} is missing IHDR or IDAT`);
  const width = header.readUInt32BE(0);
  const height = header.readUInt32BE(4);
  if (width !== spec.width || height !== spec.height || header[8] !== 8 || header[9] !== 6 || header[10] !== 0 || header[11] !== 0 || header[12] !== 0) {
    throw new Error(`${relative} has the wrong PNG format`);
  }
  const rowBytes = width * 4;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  if (raw.length !== height * (rowBytes + 1)) throw new Error(`${relative} has the wrong decoded length`);
  const pixels = Buffer.alloc(width * height * 4);
  for (let row = 0; row < height; row++) {
    const rawStart = row * (rowBytes + 1);
    if (raw[rawStart] !== 0) throw new Error(`${relative} row ${row} does not use filter byte zero`);
    raw.copy(pixels, row * rowBytes, rawStart + 1, rawStart + 1 + rowBytes);
  }
  return pixels;
}

function expectedPixels(spec) {
  const pixels = Buffer.alloc(spec.width * spec.height * 4);
  for (let offset = 0; offset < pixels.length; offset += 4) Buffer.from(spec.background).copy(pixels, offset);
  for (const cell of cells(spec.cellWidth, spec.cellHeight, spec.originX, spec.originY)) {
    if (cell.x < 0 || cell.y < 0 || cell.x + cell.width > spec.width || cell.y + cell.height > spec.height) {
      throw new Error("canonical matrix cell is outside the PNG canvas");
    }
    for (let y = cell.y; y < cell.y + cell.height; y++) {
      for (let x = cell.x; x < cell.x + cell.width; x++) Buffer.from(spec.foreground).copy(pixels, (y * spec.width + x) * 4);
    }
  }
  return pixels;
}

for (const [relative, spec] of Object.entries(assets)) {
  const actualPixels = decodePng(relative, spec);
  const expectedPixelsForAsset = expectedPixels(spec);
  if (!actualPixels.equals(expectedPixelsForAsset)) {
    let mismatch = 0;
    while (actualPixels[mismatch] === expectedPixelsForAsset[mismatch]) mismatch++;
    const pixel = Math.floor(mismatch / 4);
    throw new Error(`${relative} pixels differ at (${pixel % spec.width}, ${Math.floor(pixel / spec.width)})`);
  }
}
if (!fs.readFileSync(path.join(root, "default/plymouth/logo.png")).equals(fs.readFileSync(path.join(root, "default/sddm/omarchy/logo.png")))) {
  throw new Error("Plymouth and SDDM logos differ");
}
NODE
pass "SVG rectangles and PNG pixels match the canonical matrix and geometry"
pass "PNG branding assets have valid signatures, dimensions, colors, filters, and parity"
