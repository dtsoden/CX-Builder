# CX-Builder Migration Guide

## Current state

- **Upstream base:** Flowise 3.1.4 (tag `flowise@3.1.4`, released 2026-07-29)
- **CX-Builder version:** 5.0.0
- **Package versions:** `flowise`, `flowise-ui`, `flowise-components` all at 3.1.4
- **Brand:** CX-Builder™ (exclusive, no dual-brand toggle)
- **Upgraded from:** Flowise 3.0.12 on 2026-07-30

## Upstream is discontinued

Flowise was sunset by its original team in July 2026:

| Date | Event |
|---|---|
| 2026-07-27 | Announcement and code freeze; active development ceased |
| 2026-08-10 | GitHub repository archived; npm packages and Docker images marked deprecated |
| 2026-08-31 | End of life; original team presence ends |

**v3.1.4 is the final upstream release.** It was published on 2026-07-29, two days
after the code freeze, and CX-Builder tracks it. Barring a community fork, the upgrade
procedure below has nothing left to upgrade to and is kept for reference in case one
appears. See https://flowiseai.com/sunset.

Practical consequences:

- Nothing here breaks. CX-Builder builds every package from source in this repository,
  so the deprecation of upstream npm packages and Docker images on 2026-08-10 has no
  effect on builds or on the published `dsoden/cx-builder` image.
- There will be no further upstream security patches. Security fixes are now
  CX-Builder's own responsibility, which matters because 3.1.x carried a large number
  of them (mass assignment, IDOR, SSRF, cross-workspace disclosure).
- Clone the upstream repository before 2026-08-10 if a pristine reference copy is
  wanted. An archived repository stays readable, but do not rely on that.

## How this repo relates to upstream

CX-Builder is a squashed fork. There is no upstream remote and no shared history with
FlowiseAI/Flowise, so `git merge` against upstream does not work directly. The
procedure below reconstructs a merge base artificially, which is what produced the
3.0.12 to 3.1.4 upgrade.

`CUSTOMIZATION_MANIFEST.json` is the inventory of what CX-Builder changes relative to
pristine upstream. Treat it as a map, not as the source of truth. The source of truth
is a real diff against the pristine upstream tag.

## Upgrade procedure

Given a target tag `flowise@X.Y.Z`:

1. Clone both the current base and the target into a scratch directory:

   ```
   git clone --depth 1 --branch flowise@3.1.4 https://github.com/FlowiseAI/Flowise.git old
   git clone --depth 1 --branch flowise@X.Y.Z https://github.com/FlowiseAI/Flowise.git new
   ```

2. Build a synthetic merge base so git can do a real 3-way merge:

   ```
   git init merge-work && cd merge-work
   git config core.autocrlf false
   # commit A: pristine old upstream           -> branch "base"
   # commit B: CX-Builder HEAD, parented on A  -> branch "cx"
   # commit C: pristine new upstream, on A     -> branch "up"
   git checkout cx && git merge up
   ```

   Populate each tree with `git -C <repo> archive HEAD | tar -x`. Do not copy working
   trees, they carry CRLF conversion that turns every file into a conflict. Note that
   `git archive HEAD` exports the committed tree, so commit any edits made inside the
   scratch repo before exporting it.

3. Before merging, identify customizations that upstream has absorbed. For each file
   CX-Builder modifies, check whether its added lines already appear in the target
   version. Revert those files to the pristine old base first, so the merge takes
   upstream cleanly instead of conflicting. Verify the result afterwards: a file can be
   95% absorbed and still carry a CX-only change worth keeping.

4. Resolve conflicts by category:
   - Files CX-Builder deleted that upstream modified: keep them deleted.
   - `pnpm-lock.yaml`: take upstream's, then regenerate with `pnpm install`.
   - Everything else: merge by hand.

5. Sweep for dangling asset imports. CX-Builder deletes upstream's `*_empty.svg` files
   in favour of `EmptyStateImage`, so any new upstream view importing one breaks the
   Vite build.

6. Delete any new upstream files that landed in directories CX-Builder strips
   (`.github/`, `i18n/`, `images/`, `assets/`, `metrics/`, `docker/worker/`).

7. Rebuild the marketplace folder names (see below) if upstream adds templates.

8. Check for new upstream UI that assumes it is Flowise. 3.1.4 added an
   `AnnouncementBanner` announcing Flowise's own sunset on every page; it was removed.

## What CX-Builder customizes

### Branding
Logos (`cxbuilder_*.svg`), favicons (`cx-icon.*`), the `EmptyStateImage` component and
its 31 call sites, email templates, `AboutDialog`, `Logo`, `index.html` titles, and
`manifest.json`.

### Theme
`_themes-vars.module.scss`, `themes/index.js`, `themes/palette.js`,
`themes/compStyleOverride.js`, `StyledButton.jsx`, `StyledFab.jsx`.
Brand colours: navy `#003D5B`, teal `#24E2CB`, gold hover `#fbca1b`.

### Marketplace folder system
`packages/server/src/services/marketplaces/index.ts` scans marketplace folders
dynamically and derives the canvas type from the folder name:

| Folder | Upstream name | Canvas type |
|---|---|---|
| `Chat` | `chatflows` | chatflow |
| `Agents-V1` | `agentflows` | v1 |
| `Agents-V2` | `agentflowsv2` | v2 |
| `Tools` | `tools` | tool |

A `-V1`/`-V2` suffix sets the canvas type and is stripped from the display name; a
folder named `tools` (case insensitive) is the tool type; anything else is a chatflow.
Template JSON contents are unmodified from upstream, only the folders are renamed.

### Label indirection
`chatflowLabel` in `APICodeDialog.jsx` and `docstoreTitle` in `docstore/index.jsx` are
constants that currently equal the upstream wording. They exist so terminology can be
changed in one place. They are no-ops today.

### Infrastructure (CX-Builder only, no upstream counterpart)
`Dockerfile` (multi-stage, avoids a 2.9GB chown layer), `docker/Dockerfile.local`,
`docker/docker-compose.yml` (bundles pgvector), `docker/docker-compose.local.yml`,
`docker/docker-compose.dev.yml`, `docker/DOCKERHUB_README.md`, `install.sh`,
`install.ps1`, and a curated `docker/.env.example` whose variables match the compose
file exactly so `docker compose` emits no warnings.

### Deletions
Upstream CI workflows, issue templates, funding config, `i18n/`, `images/`, `assets/`,
`metrics/`, `docker/worker/`, the queue compose files, `CONTRIBUTING.md`,
`CODE_OF_CONDUCT.md`, `SECURITY.md`, and 29 unused image assets.

## Storage paths must match the container user

The image runs as `USER node`, so all storage paths must live under
`/home/node/.flowise`, never `/root/.flowise`. A non-root user cannot write to
`/root`, and the server crash-loops with EACCES if it tries.

This was fixed in the installers in February but `docker/.env.example` was missed, so
anyone following the manual `cp .env.example .env` path got a crash-looping stack.
Corrected 2026-07-30. If these paths are ever edited, change them in all three places:
`docker/.env.example`, `install.sh` and `install.ps1`.

## Build requirements

- Node 24 (`.nvmrc` pins v24.15.0); 3.0.12 wanted Node 20
- pnpm 10.26.0 or newer
- `pnpm build:docker` rather than `pnpm build`. It skips `@flowiseai/agentflow` and
  `@flowiseai/observe`, two SDK packages added in 3.1.x that neither the server nor the
  UI depends on.
- `pnpm exec oclif manifest` must run in `packages/server` after the build. The server
  lists `oclif.manifest.json` in its `files` array and the CLI crash-loops without it.
- UI build output is `packages/ui/build`, not `dist`.

## Publishing the image

`dsoden/cx-builder:latest` is multi-architecture (`linux/amd64` + `linux/arm64`). See
"Pushing to Docker Hub" in the root README for exact commands. Two things are easy to
get wrong:

- It builds from the root `Dockerfile`, not `docker/Dockerfile.local`. The README
  documented the wrong one until 2026-07-30.
- It needs the `docker-container` buildx driver. The default driver cannot emit a
  manifest list, so `--platform linux/amd64,linux/arm64` will not work.

arm64 builds under QEMU emulation on x86 hosts at roughly 10-15x the amd64 time
(~11 minutes versus ~50 seconds for the build stage).

The Docker Hub repository description is `docker/DOCKERHUB_README.md`. It is not
synced automatically; paste it into Docker Hub when it changes.

## Notes on the 3.0.12 to 3.1.4 upgrade

Most of what used to be CX-Builder's own server-side code was adopted upstream during
3.1.x and was dropped in favour of upstream's version: the Azure rerank retriever and
its credential, `fileValidation.ts`, the MIME validation helpers in `validator.ts` and
`utils.ts`, Cerebras chat model support, Postgres schema qualification, the BullMQ
dashboard auth guard, the rate-limiter lookup, and the `get-upload-path` route removal.
See `absorbedUpstream` in the manifest for the full list.

Flowise 3.1.0 enabled outbound HTTP security checks by default. `HTTP_SECURITY_CHECK`
and `HTTP_DENY_LIST` were added to `docker/docker-compose.yml` and
`docker/.env.example` so operators can adjust it. Flows that call internal services or
localhost will be blocked until it is turned off.

## Verified on 3.1.4

The amd64 image was booted end to end: migrations applied, `/api/v1/ping` returned 200,
`/api/v1/version` reported 3.1.4, the marketplace folder derivation resolved correctly
(Chat 24 chatflow, Agents-V1 14 v1, Agents-V2 13 v2, Tools 13 tool), and the UI served
with CX-Builder branding.

The arm64 image was booted separately on an Apple Silicon M4: it pulled, started and
reached the account setup screen, which only renders after migrations have applied and
the server has bound its port. Docker selects the native architecture by default when
the manifest offers it, so this exercised the arm64 layer rather than Rosetta.
