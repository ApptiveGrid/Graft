# Graft

Metacello dependency graph tool for the ApptiveGrid Pharo ecosystem. Parses `BaselineOf` classes across a set of tracked projects, builds a cross-repo dependency graph, detects commit-pinned references that are behind their target's current tip, and computes/previews the cascade of `BaselineOf` edits needed to bump a project's dependents (and their dependents, and so on) onto a new commit.

v1 scope: preview/diff only, no automatic commit or push into the managed repos. See `Graft-Core`, `Graft-Core-Tests`, `Graft-UI`.
