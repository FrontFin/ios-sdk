---
description: Bump the MeshPay iOS SDK version (VERSION + Version.swift + CHANGELOG) and open a release PR.
---

Bump the SDK version in lockstep across the two files CI checks, add the changelog
entry, and open the PR that `release.yml` turns into a tagged GitHub Release.

Arguments: an optional bump type — `patch` (default), `minor`, or `major` — or an
explicit `X.Y.Z`.

Steps:

1. Read the current version from `VERSION`.
2. Compute the new version from the argument (semver bump, or the explicit value).
   Refuse if it is not strictly greater than the current one.
3. Update **both** of these to the new version — they MUST match or CI fails:
   - `VERSION` (the bare `X.Y.Z`, one line).
   - `Sources/MeshpayLink/Version.swift` (`static let current = "X.Y.Z"`).
4. Add a `## X.Y.Z` section at the top of `CHANGELOG.md` (under the header),
   following Keep a Changelog, summarising what changed since the last tag. Every
   release needs an entry — the release workflow fails without a matching `## X.Y.Z`.
5. Create a branch named `prg-<ticket>-release-X.Y.Z` (never a username prefix),
   commit the three files, and open a PR into `main` with the ticket link and a
   short summary. Do not tick any checklist boxes.

On merge, `release.yml` detects the bump, re-runs CI, and creates the plain
`X.Y.Z` tag + GitHub Release that Swift Package Manager resolves. There is no
separate publish step.
