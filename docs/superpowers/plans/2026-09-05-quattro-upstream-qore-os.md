# Quattro Upstream Sync and qore.os Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the current Omarchy `quattro` history into Ocyarhm without rewriting the fork, preserve the ISO framework, and replace every approved default visual logo with a deterministic `qore.os` wordmark.

**Architecture:** The fork remains an `omarchy`-compatible source tree and keeps all existing command, package, path, and workflow identifiers. A single 5x7 pixel matrix is the source geometry for the terminal text assets, SVG wordmark, square icon, Plymouth splash logo, and SDDM greeter logo.

**Tech Stack:** Git, Bash shell tests, SVG, PNG RGBA assets, and a temporary Python standard-library generator used only to emit deterministic PNG files.

**Spec:** `docs/superpowers/specs/2026-09-05-quattro-upstream-qore-os-design.md`

## Global Constraints

- Merge upstream `quattro` into Ocyarhm `quattro` with a non-fast-forward merge commit.
- Preserve the `v4.0.2` ancestor and all Ocyarhm-only ISO/build and sync automation commits.
- Do not rebase, squash, force-push, or rename the `quattro` branch.
- Keep internal `omarchy-*` command names, package names, filesystem paths, the ISO builder repository, and unrelated `default/plymouth/logos/oma.png` unchanged.
- Use the literal custom wordmark `qore.os`, including its period, in every approved visible default asset.
- Use the exact matrix below for every generated asset; do not depend on a runtime font or AI text rendering.
- Focused tests must pass; report any unavailable Linux/GUI/ISO environment instead of claiming unverified runtime behavior.

Canonical glyph rows, with `1` as a filled cell and `0` as an empty cell:

```text
q = 01110 10001 10001 10001 01111 00001 00001
o = 01110 10001 10001 10001 10001 10001 01110
r = 11110 10001 10001 11110 10100 10010 10001
e = 01110 10001 10000 11110 10000 10001 01110
. = 00000 00000 00000 00000 00000 00110 00110
s = 01111 10000 10000 01110 00001 00001 11110
```

The seven glyphs are separated by one empty matrix column, giving a 41-column wordmark. The terminal representation expands every matrix column to two characters (`██` or two spaces), producing this exact seven-line `logo.txt`/`icon.txt` content:

```text
  ██████      ██████    ████████      ██████                  ██████      ████████
██      ██  ██      ██  ██      ██  ██      ██              ██      ██  ██
██      ██  ██      ██  ██      ██  ██                      ██      ██  ██
██      ██  ██      ██  ████████    ████████                ██      ██    ██████
  ████████  ██      ██  ██  ██      ██                      ██      ██          ██
        ██  ██      ██  ██    ██    ██      ██      ████    ██      ██          ██
        ██    ██████    ██      ██    ██████        ████      ██████    ████████
```

---

### Task 1: Merge the complete upstream quattro history

**Files:**
- Modify: the files carried by the four missing upstream commits, including `bin/omarchy*`, `default/fonts/omarchy/`, `default/omarchy/omarchy-menu.jsonc`, `install/omarchy-base.packages`, `manual/17-ai.md`, `manual/18-development-tools.md`, `migrations/1788595060.sh`, `migrations/1788596255.sh`, and the related shell tests under `test/shell.d/`.

**Interfaces:**
- Consumes: `v4.0.2`, `upstream/quattro`, current Ocyarhm `quattro`, and the existing fork-only automation commits.
- Produces: one merge commit on `codex/quattro-sync-qore-os` whose second parent is the current upstream `quattro` tip.

- [ ] **Step 1: Confirm the implementation worktree is clean and record the source SHAs**

Run from the repository root:

```bash
git status --short --branch
git fetch --no-tags upstream refs/tags/v4.0.2:refs/tags/v4.0.2 refs/heads/quattro:refs/remotes/upstream/quattro
base_sha=$(git rev-parse HEAD)
security_sha=$(git rev-parse v4.0.2)
upstream_sha=$(git rev-parse upstream/quattro)
printf 'base=%s security=%s upstream=%s\n' "$base_sha" "$security_sha" "$upstream_sha"
```

Expected: the worktree is clean, `security_sha` is `346e69e1cec6c4e8924531874af6ba010a1bc99e`, and `upstream_sha` is `eb56446c4286c2d01bed3ed25d937850fc3b4810` unless upstream moves before execution.

- [ ] **Step 2: Verify the pre-merge divergence and security ancestry**

```bash
git merge-base --is-ancestor v4.0.2 HEAD
test "$(git rev-list --count v4.0.2..upstream/quattro)" -eq 275
test "$(git rev-list --left-right --count HEAD...upstream/quattro)" = "7 4"
```

Expected: all commands succeed; the fork has seven commits not on upstream and upstream has four commits not yet in the fork.

- [ ] **Step 3: Merge upstream without rewriting the fork**

```bash
git -c user.name='Codex' -c user.email='codex@openai.local' merge --no-ff --no-edit upstream/quattro
```

Expected: Git creates a merge commit with the current fork tip as first parent and `upstream/quattro` as second parent, with no conflicts because the four missing upstream commits do not modify the fork-owned automation or approved branding files.

- [ ] **Step 4: Verify the resulting ancestry and preserved automation commits**

```bash
git merge-base --is-ancestor v4.0.2 HEAD
git merge-base --is-ancestor upstream/quattro HEAD
git merge-base --is-ancestor 582e00cd HEAD
git merge-base --is-ancestor 5da590d1 HEAD
git merge-base --is-ancestor 22f6b1fd HEAD
test -f .github/workflows/build-iso.yml
test -f .github/workflows/sync-upstream.yml
test -f docs/maintainer-automation.md
git diff --check HEAD^1 HEAD
```

Expected: both upstream/security ancestry checks, all three fork-commit checks, file checks, and whitespace validation succeed.

- [ ] **Step 5: Commit the merge as the atomic upstream synchronization**

If Step 3 created a merge commit, retain that commit as the task’s synchronization commit and record it with:

```bash
git show --no-patch --format='%H%n%P%n%s' HEAD
git rev-list --count v4.0.2..HEAD
```

Expected: the displayed commit has two parents, the second parent is `upstream_sha`, and all pre-existing fork-only commits remain reachable.

### Task 2: Add a failing branding regression test

**Files:**
- Create: `test/shell.d/branding-assets-test.sh`

**Interfaces:**
- Consumes: the repository root discovered by `test/shell.d/base-test.sh` and the six packaged branding assets.
- Produces: a shell-test entry that rejects stale Omarchy defaults, malformed qore.os text, invalid SVG metadata, mismatched PNG dimensions, and divergent Plymouth/SDDM logos.

- [ ] **Step 1: Create the test with the canonical expected text and asset checks**

Create `test/shell.d/branding-assets-test.sh` with this content:

```bash
#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

expected=$(
  cat <<'WORDMARK'
  ██████      ██████    ████████      ██████                  ██████      ████████
██      ██  ██      ██  ██      ██  ██      ██              ██      ██  ██
██      ██  ██      ██  ██      ██  ██                      ██      ██  ██
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
```

- [ ] **Step 2: Run the new test before changing assets**

```bash
./test/shell.d/branding-assets-test.sh
```

Expected: FAIL against the current Omarchy assets because the text wordmark, SVG title, and PNG dimensions do not yet match qore.os.

### Task 3: Implement the shared qore.os assets

**Files:**
- Modify: `logo.txt`
- Modify: `icon.txt`
- Modify: `logo.svg`
- Modify: `icon.png`
- Modify: `default/plymouth/logo.png`
- Modify: `default/sddm/omarchy/logo.png`
- Create temporarily in `work/`: `generate-qore-os-assets.py`

**Interfaces:**
- Consumes: the canonical 5x7 matrix and existing surface dimensions/colors.
- Produces: exact shared text branding and six matching graphical defaults; no runtime code or ISO workflow changes.

- [ ] **Step 1: Replace the text assets with the exact expected block wordmark**

Apply the seven-line `WORDMARK` content from Task 2 to both `logo.txt` and `icon.txt`, ending each file with one LF newline and no trailing spaces on any row.

- [ ] **Step 2: Replace the SVG with deterministic crisp rectangles**

Create an SVG with `width="1215"`, `height="285"`, and `viewBox="0 0 1215 285"`. Add `<title>qore.os</title>`, `shape-rendering="crispEdges"`, and one black `<rect>` for every filled matrix cell using `cell_width=25`, `cell_height=30`, `origin_x=95`, and `origin_y=37`. Do not use a `<text>` element or an external font.

- [ ] **Step 3: Generate the three PNG defaults from the same matrix**

Create `work/generate-qore-os-assets.py` with the matrix and a standard-library PNG encoder. The generator must emit 8-bit RGBA PNGs with these exact parameters:

```python
assets = {
    "icon.png": (300, 300, (158, 206, 106, 255), (0, 0, 0, 255), 5, 20, 47, 80),
    "default/plymouth/logo.png": (800, 188, (0, 0, 0, 0), (168, 205, 118, 255), 18, 22, 31, 17),
    "default/sddm/omarchy/logo.png": (800, 188, (0, 0, 0, 0), (168, 205, 118, 255), 18, 22, 31, 17),
}
```

For each asset, draw every filled matrix cell as a solid rectangle at `(origin_x + column * cell_width, origin_y + row * cell_height)` and leave all empty cells transparent/background. Write the PNG signature, an IHDR chunk for the declared dimensions/8-bit RGBA, one zlib-compressed scanline per image row with filter byte zero, and an IEND chunk. Copying the resulting Plymouth logo to SDDM is allowed only after both files pass the dimension/parity checks.

- [ ] **Step 4: Run the focused branding test**

```bash
./test/shell.d/branding-assets-test.sh
```

Expected: PASS for text, SVG, and PNG checks.

- [ ] **Step 5: Inspect the generated images and asset diffs**

```bash
git diff --check
git diff --stat
git status --short
```

Use the image viewer on `icon.png`, `default/plymouth/logo.png`, and `default/sddm/omarchy/logo.png`. Expected: readable `qore.os`, no clipping, transparent wordmark backgrounds for boot/login logos, the existing light-green square icon treatment, and identical Plymouth/SDDM wordmarks.

- [ ] **Step 6: Commit the branding change separately from the merge**

```bash
git add logo.txt icon.txt logo.svg icon.png default/plymouth/logo.png default/sddm/omarchy/logo.png test/shell.d/branding-assets-test.sh
git -c user.name='Codex' -c user.email='codex@openai.local' commit -m "feat: brand default visuals as qore.os"
```

### Task 4: Validate integration, installer coverage, and publication

**Files:**
- Verify only: `.github/workflows/build-iso.yml`, `.github/workflows/sync-upstream.yml`, `docs/maintainer-automation.md`, `logo.txt`, and the six branded assets.

**Interfaces:**
- Consumes: the merged and branded branch.
- Produces: evidence that the ISO framework still reads the fork’s qore.os source and a non-force-pushable branch ready for the fork.

- [ ] **Step 1: Run the focused shell test through Git for Windows Bash**

```bash
./test/shell.d/branding-assets-test.sh
./test/cli
```

Expected: the new branding test passes. The CLI suite should pass or report only host-specific failures; do not treat the earlier aggregate failures caused by missing Linux commands, `/usr/bin/python3^M` shebangs, or unavailable graphical dependencies as branding regressions.

- [ ] **Step 2: Confirm the actual ISO builder reads the changed source asset**

From the separately checked-out `omarchy-iso` source, verify:

```bash
grep -Fq 'LOGO_PATH="$OMARCHY_PATH/logo.txt"' configs/airootfs/root/configurator
grep -Fq 'LOGO_PATH="${OMARCHY_PATH:-/usr/share/omarchy}/logo.txt"' configs/airootfs/usr/local/bin/omarchy-install-dashboard
grep -Fq -- '--local-source' bin/omarchy-iso-make
```

Expected: all checks pass; no change to the external ISO builder is required because the existing Ocyarhm workflow mounts the fork source read-only and the builder consumes its `logo.txt`.

- [ ] **Step 3: Re-check merge ancestry and fork automation after branding**

```bash
git merge-base --is-ancestor v4.0.2 HEAD
git merge-base --is-ancestor upstream/quattro HEAD
git merge-base --is-ancestor 582e00cd HEAD
git merge-base --is-ancestor 5da590d1 HEAD
test -f .github/workflows/build-iso.yml
test -f .github/workflows/sync-upstream.yml
git diff --check HEAD~2 HEAD
git status --short --branch
```

Expected: all checks pass and the worktree is clean.

- [ ] **Step 4: Publish the implementation branch without rewriting remote history**

```bash
git push --set-upstream origin codex/quattro-sync-qore-os
git push origin HEAD:quattro
```

The first push publishes the verified branch. The second is a normal non-force update of `origin/quattro`; if branch protection rejects it, retain the published implementation branch and report that the fork requires its normal pull-request merge path. Never add `--force`.

- [ ] **Step 5: Record the final verification evidence**

Capture the merge SHA, upstream SHA, security-tag SHA, focused-test result, asset dimensions, and whether direct `quattro` publication was accepted. State explicitly if the full ISO build or graphical runtime verification could not run on this host.
