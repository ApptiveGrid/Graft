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

