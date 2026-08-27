# Maintainer automation

Ocyarhm keeps `quattro` as its default integration branch. Automation never force-updates or merges that branch.

## Upstream synchronization

[`sync-upstream.yml`](../.github/workflows/sync-upstream.yml) runs weekly and can also be dispatched manually. Each run checks out the current Ocyarhm `quattro`, fetches `basecamp/omarchy:quattro`, and attempts a normal merge locally. A conflict fails the job before anything is pushed.

A clean merge is pushed without force to `automation/sync-omarchy-<ocyarhm-sha>-<upstream-sha>`. The two source SHAs make the branch unique to that synchronization attempt. The workflow opens a pull request from that branch to `quattro`, or reuses its existing open pull request. Maintainers review it through the normal repository policy; the workflow never merges it. If upstream is already contained in `quattro`, the run exits without creating a branch or pull request.

Merge every synchronization pull request with GitHub's **Create a merge commit** option. Never use **Squash and merge** or **Rebase and merge** for these pull requests. A merge commit retains the fetched Omarchy commit in `quattro`'s ancestry, which is what lets later runs recognize already-integrated upstream history. Squashing or rebasing destroys that ancestry and causes future synchronization runs to propose the same upstream changes again.

### Automation credential

Create one repository Actions secret named `OCYARHM_AUTOMATION_TOKEN`. Its value must be a dedicated fine-grained personal access token or GitHub App installation token scoped only to the Ocyarhm repository, with these repository permissions:

- **Contents: Read and write** to create `automation/sync-omarchy-*` branches.
- **Pull requests: Read and write** to find and create synchronization pull requests.
- **Metadata: Read**, which GitHub grants implicitly.

Do not grant administration, workflow, Actions, checks, or other unrelated permissions. Do not give the token's user or App a ruleset or protected-branch bypass; `quattro` must continue to require the normal pull request and status-check path. Repository **Settings → Actions → General → Workflow permissions** must enable **Allow GitHub Actions to create and approve pull requests**; this workflow creates pull requests but never approves them. Repository pull request settings must also allow merge commits so maintainers can select **Create a merge commit**.

The workflow's built-in `GITHUB_TOKEN` has only `contents: read`, and checkout does not persist it. The dedicated secret is used for both the automation-branch push and `gh pr create`, so the resulting pull request event is attributed to that automation identity and can start the repository's required checks. There is no built-in-token fallback: a missing secret fails the workflow with setup instructions before any remote mutation.

Run it from a checkout authenticated with GitHub CLI:

```bash
gh workflow run sync-upstream.yml --ref quattro
gh run watch
```

If a merge conflicts, resolve the divergence in a maintainer-owned branch and open a normal pull request. Do not rewrite `quattro` or force-push the automation branch.

## On-demand ISO builds

[`build-iso.yml`](../.github/workflows/build-iso.yml) has no schedule. It accepts a branch, tag, or commit for Ocyarhm and each supported infrastructure repository:

```bash
gh workflow run build-iso.yml --ref quattro \
  -f ocyarhm_ref=quattro \
  -f iso_ref=quattro \
  -f pkgs_ref=master
gh run watch
```

For an audit-oriented build, pass full commit SHAs instead of moving branch names. The workflow resolves every requested ref, checks out Ocyarhm plus `omacom-io/omarchy-iso` and `omacom-io/omarchy-pkgs`, and invokes the official builder with `--no-cache --keep-pkg-cache --no-boot-offer --local-source`. This packages the selected local Ocyarhm source with the selected package recipes and avoids interactive cache and boot prompts.

The uploaded `ocyarhm-iso-<run-id>-<attempt>` artifact contains every file emitted by the builder's `release/` directory, `source-manifest.txt`, and `SHA256SUMS`. Artifacts are retained for 14 days. Download and verify one with:

```bash
gh run download <run-id> -n ocyarhm-iso-<run-id>-<attempt>
sha256sum -c SHA256SUMS
```

These workflow artifacts are unsigned test builds, not releases.

## Provenance, not byte-for-byte reproducibility

`source-manifest.txt` records the requested refs, resolved commit SHAs, GitHub run identity, runner image version, builder flags, build time, and the pulled Arch Linux container image digest. Together with `SHA256SUMS`, this identifies the source inputs and verifies the downloaded ISO bytes.

The manifest does not make the build byte-for-byte reproducible. The upstream builder intentionally resolves floating Arch and Omarchy package mirrors, the latest Node.js release, the `archlinux/archlinux:latest` image, and build timestamps. Those external inputs can change even when all three Git commit SHAs stay fixed. Treat the manifest as provenance and traceability for a particular run, not as a promise that rerunning it will produce the same ISO hash.
