# Quattro Upstream Sync and qore.os Branding Design

## Goal

Bring the Ocyarhm `quattro` branch fully up to the current Omarchy `quattro` history, retaining the `v4.0.2` security-release ancestry and all Ocyarhm-specific ISO/build automation, then replace every default visible logo asset with the exact custom `qore.os` wordmark.

## Current state

- The Ocyarhm fork currently uses `quattro` as its integration branch.
- Upstream `v4.0.2` is an ancestor of both repositories.
- Upstream `quattro` contains 275 commits after `v4.0.2`.
- Ocyarhm currently has seven fork-only commits, including ISO build and upstream-sync automation, and is four upstream commits behind the current upstream `quattro` tip.
- The ISO builder is a separate `omacom-io/omarchy-iso` checkout, but its live installer and dashboard read `OMARCHY_PATH/logo.txt`; the Ocyarhm source checkout supplies that file through the existing `--local-source` workflow.

## Approved approach

### Upstream integration

Fetch the upstream `v4.0.2` tag and the current `omacom/omarchy:quattro` branch, then merge the upstream tip into Ocyarhm `quattro` with a non-fast-forward merge commit. Preserve the public fork history, all fork-only commits, and the existing ISO build/sync workflows. Do not rebase, squash, force-push, or rename the branch.

The resulting branch must prove that both `v4.0.2` and the complete upstream `quattro` tip are ancestors, while each Ocyarhm-only automation commit remains reachable. The existing sync workflow must remain idempotent after the merge: it should detect that the fetched upstream tip is already contained and avoid proposing the same sync again.

### Branding

Use one deterministic 5x7 block-letter matrix for the literal text `qore.os`, including a visible period. Derive all text and graphical assets from that same geometry so the wordmark is exact and does not depend on an installed font or AI text rendering.

Update these tracked defaults:

- `logo.txt`, consumed by terminal presentation commands, first-boot provisioning, and the live ISO installer/dashboard.
- `icon.txt`, consumed when About branding is reset to its packaged default.
- `logo.svg`, the repository vector wordmark.
- `icon.png`, the repository square icon, using the qore.os wordmark centered on the existing light-green/black visual convention.
- `default/plymouth/logo.png`, the default boot splash wordmark.
- `default/sddm/omarchy/logo.png`, the default login-greeter wordmark.

Keep internal `omarchy-*` command names, package names, filesystem paths, the ISO builder repository, and unrelated secondary assets such as `default/plymouth/logos/oma.png` unchanged for compatibility.

### Verification

Run the repository’s focused shell tests in a Linux-capable environment when available. On this Windows host, record the absence of WSL/bash if Linux execution is unavailable, and still perform deterministic checks for merge ancestry, clean status, exact text assets, SVG validity, PNG signatures/dimensions, asset parity, and preserved ISO workflow files. The implementation must not claim full runtime verification unless the ISO/installer test harness or a Linux environment is actually available.

## Success criteria

1. Ocyarhm `quattro` contains the upstream `quattro` tip through a merge commit and retains all fork-only commits.
2. `v4.0.2` remains in the resulting ancestry.
3. `.github/workflows/build-iso.yml`, `.github/workflows/sync-upstream.yml`, and `docs/maintainer-automation.md` remain present and functional under the existing workflow contract.
4. Terminal, first-boot, and ISO installer logo consumers read `qore.os` from `logo.txt`.
5. About reset, SVG, square icon, Plymouth, and SDDM defaults visibly use `qore.os`.
6. No internal compatibility identifiers are renamed.
7. Focused tests and deterministic asset checks pass, with any environment limitation reported explicitly.
