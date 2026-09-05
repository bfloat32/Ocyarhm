#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command node

node - "$ROOT" <<'NODE'
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const root = process.argv[2];
const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const MATRIX = [
  "01110001110011110001110000000001110001111",
  "10001010001010001010001000000010001010000",
  "10001010001010001010000000000010001010000",
  "10001010001011110011110000000010001001110",
  "01111010001010100010000000000010001000001",
  "00001010001010010010001000110010001000001",
  "00001001110010001001110000110001110011110",
];
if (MATRIX.length !== 7 || MATRIX.some((row) => !/^[01]{41}$/.test(row))) {
  throw new Error("canonical qore.os matrix is not 41 columns by seven rows");
}
const WORDMARK = MATRIX.map((row) => [...row].map((cell) => cell === "1" ? "██" : "  ").join(""));
const expectedText = WORDMARK.map((row) => row.trimEnd()).join(String.fromCharCode(10)) + String.fromCharCode(10);

for (const relative of ["logo.txt", "icon.txt"]) {
  if (fs.readFileSync(path.join(root, relative), "utf8") !== expectedText) {
    throw new Error(`${relative} does not match the canonical qore.os matrix`);
  }
}
if (!fs.readFileSync(path.join(root, "logo.txt")).equals(fs.readFileSync(path.join(root, "icon.txt")))) {
  throw new Error("terminal and About defaults do not share one wordmark");
}

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
  for (let row = 0; row < MATRIX.length; row++) {
    for (let column = 0; column < MATRIX[row].length; column++) {
      if (MATRIX[row][column] === "1") {
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

function attributes(source, context) {
  const parsed = [...source.matchAll(/ ([A-Za-z_:][A-Za-z0-9_.:-]*)="([^"<>&]*)"/g)];
  if (parsed.map((match) => match[0]).join("") !== source) {
    throw new Error(`${context} has malformed or unpermitted attributes`);
  }
  const values = new Map(parsed.map((match) => [match[1], match[2]]));
  if (values.size !== parsed.length) throw new Error(`${context} repeats an attribute`);
  return values;
}

function requireExactAttributes(actual, expected, context) {
  if (actual.size !== Object.keys(expected).length) throw new Error(`${context} has unexpected attributes`);
  for (const [name, value] of Object.entries(expected)) {
    if (!actual.has(name) || actual.get(name) !== value) throw new Error(`${context} has the wrong ${name} attribute`);
  }
}

const svg = fs.readFileSync(path.join(root, "logo.svg"), "utf8");
const documentMatch = svg.match(/^<svg((?: [A-Za-z_:][A-Za-z0-9_.:-]*="[^"<>&]*")*)>\r?\n  <title>qore\.os<\/title>\r?\n((?:  (?:<rect(?: [A-Za-z_:][A-Za-z0-9_.:-]*="[^"<>&]*")*\/>)+\r?\n)+)<\/svg>\r?\n?$/u);
if (!documentMatch) throw new Error("logo.svg is not a complete permitted SVG document");
requireExactAttributes(attributes(documentMatch[1], "SVG root"), {
  xmlns: "http://www.w3.org/2000/svg",
  width: "1215",
  height: "285",
  viewBox: "0 0 1215 285",
  "shape-rendering": "crispEdges",
}, "SVG root");

const actualRects = [...documentMatch[2].matchAll(/<rect((?: [A-Za-z_:][A-Za-z0-9_.:-]*="[^"<>&]*")*)\/>/g)].map((match) => {
  const rectAttributes = attributes(match[1], "SVG rectangle");
  requireExactAttributes(rectAttributes, {
    fill: "black",
    x: rectAttributes.get("x"),
    y: rectAttributes.get("y"),
    width: "25",
    height: "30",
  }, "SVG rectangle");
  return {
    x: Number(rectAttributes.get("x")), y: Number(rectAttributes.get("y")),
    width: Number(rectAttributes.get("width")), height: Number(rectAttributes.get("height")),
    fill: rectAttributes.get("fill"),
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
pass "text branding uses the exact qore.os matrix"
pass "SVG branding is a complete permitted qore.os document"
pass "SVG rectangles and PNG pixels match the canonical matrix and geometry"
pass "PNG branding assets have valid signatures, dimensions, colors, filters, and parity"
