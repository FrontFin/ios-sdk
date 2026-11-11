---
description: Bump the Mesh iOS SDK version (VERSION + Version.swift + CHANGELOG) and open a release PR.
---

Bump the SDK version in lockstep across the two files CI checks, add the changelog
entry, and open the release PR. There is no release workflow yet: after the PR
merges, the release is tagged by hand (step 6).

Arguments: an optional bump type — `patch` (default), `minor`, or `major` — or an
explicit `X.Y.Z`.

Steps:

1. Read the current version from `VERSION`.
2. Compute the new version from the argument (semver bump, or the explicit value).
   Refuse if it is not strictly greater than the current one.
3. Update **both** of these to the new version — they MUST match or CI fails:
   - `VERSION` (the bare `X.Y.Z`, one line).
   - `Sources/MeshLink/Version.swift` (`static let current = "X.Y.Z"`).
4. Add a `## X.Y.Z` section at the top of `CHANGELOG.md` (under the header),
   following Keep a Changelog, summarising what changed since the last tag. Every
   release needs a matching `## X.Y.Z` entry.
5. Create a branch named `prg-<ticket>-release-X.Y.Z` (never a username prefix),
   commit the three files, and open a PR into `main` with the ticket link and a
   short summary. Do not tick any checklist boxes.

6. After the PR merges, tag the merge commit on `main` and publish the GitHub
   Release. Swift Package Manager resolves versions only from git tags, so the
   release does not exist until this is done:

   ```bash
   git fetch origin main
   git tag X.Y.Z <merge-commit-sha>   # plain X.Y.Z, no "v"; must equal VERSION
   git push origin X.Y.Z
   gh release create X.Y.Z --title X.Y.Z --notes "<the ## X.Y.Z CHANGELOG section>"
   ```

   Check first that `VERSION` and `Version.swift` on that commit both read `X.Y.Z`.
