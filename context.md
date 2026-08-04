# Graft

Graft is a Pharo/Smalltalk tool that manages Metacello `BaselineOf` dependencies
across a set of related repositories.

It targets ecosystems where cross-project dependencies aren't declared through
Metacello's `spec version: 'x.y.z'` mechanism, but via a `repository:` URL string
with an optional `:ref` segment, e.g. `github://SomeOrg/SomeProject:a0b4d1f/source`.
A reference falls into one of three kinds:

- **Commit-pinned** — points at a specific commit hash. Stays fixed until someone
  manually bumps it, even after the target project moves on.
- **Branch-pinned** — points at a branch name and floats with it automatically.
- **Unpinned** — no `:ref` at all, floats on the target's default branch.

Only commit-pinned references can go stale: if project C gets a new commit and
project B references C via a commit pin, B's pin is now behind C's tip. If
project A in turn commit-pins B, that staleness cascades further upstream.

Graft builds a dependency graph across the known projects, detects
which commit-pinned references are stale, and computes/previews the cascade of
`BaselineOf` edits needed to bring a project's dependents (and their dependents,
and so on) onto a new commit. It can then apply a chosen subset of those edits —
rewriting the affected `repository:` strings and, optionally, committing.

Graft ships as a Spec2 GUI (`Graft-UI`, graph visualization via Roassal) on top
of a plain domain model (`Graft-Core`), installed via `BaselineOfGraft`.

Design constraints:
- Never pushes automatically; only commits when explicitly requested.
- Won't silently overwrite unrelated work — it blocks on foreign uncommitted
  changes or a branch mismatch, but can offer to work around either (bundle the
  change, or switch to a fresh update branch) rather than just refusing.

## Key decisions

## Planned extension: release-cutting support

A collaborator proposed a "Spec Release Assistant": instead of only catching
dependents up to an already-existing commit, let the user decide per
dependency how it should be pinned — including minting new tags — as part of
cutting a release across a whole dependency tree. Rather than a separate tool,
this extends Graft in place:

- [ ] Recognize tags as a distinct pin kind. A tag name and a branch name look
      the same syntactically, so this needs a live repo lookup to disambiguate
      (`GftVersionResolver refKindFor:in:`), not just string shape.
- [ ] Root-based recursive dependency discovery with cycle detection
      (`GftDependencyGraph buildFrom:`), alongside the existing flat,
      managed-scope `build`. Track a path stack, not just a visited set, so a
      shared/diamond dependency isn't misreported as a cycle.
- [ ] Per-reference action choice (`GftReferenceChoice`: bump to latest tip,
      pin a specific commit, use a branch, use an existing tag, or create a
      release) instead of today's implicit "always bump to latest tip".
- [ ] Tag creation in the apply path (`GftUpdater createTag:message:on:`),
      reusing the existing round-based, bottom-up update loop rather than
      building a new topological sort.
- [ ] Scope the baseline rewriter's substring search to the specific
      method/reference instead of the whole class — tag names are far less
      unique than commit SHAs, so a class-wide search risks a wrong match.
- [ ] AST-based fallback parsing (`RBParser`) for BaselineOf classes that
      aren't loaded in the image. Live introspection already fails on real
      cases (e.g. `apptive-account`'s baseline erroring on `#openAPI:`), but
      the AST fallback can't resolve helper-method indirections like
      `commonCommitHash` — mark those references as only partially resolved
      rather than guessing.
- [ ] Separately decide whether to fetch source for repositories that aren't
      checked out at all. That breaks the "no automatic network access"
      guardrail above and needs its own explicit go-ahead, not a side effect
      of the rest of this list.

